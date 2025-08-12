# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os
import json
import logging
from typing import Dict, Any
from strands import Agent
from strands.models import BedrockModel
from strands.tools.mcp import MCPClient
from mcp.client.streamable_http import streamablehttp_client
from mcp.client.sse import sse_client
from pydantic import ValidationError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

MERCH_ALB_DNS = os.getenv('MERCH_ALB_DNS')
TRANS_ALB_DNS = os.getenv('TRANS_ALB_DNS')
SEARCH_ALB_DNS = os.getenv('SEARCH_ALB_DNS')
FETCH_ALB_DNS = os.getenv('FETCH_ALB_DNS')
MCP_PATH = os.getenv('MCP_PATH')

MODEL_ID =  os.getenv('AGENT_MODEL') 
ACTION_GROUP_DETAIL = {
    "merchant_portfolio_agent": {
        "prompt": "This agent can answer questions related to merchants portfolio and fetch data such as the merchant name, address, website, phone number and other merchant metadata",
        "endpoint": f"http://{MERCH_ALB_DNS}{MCP_PATH}"
    },
    "merchant_stats_agent": {
        "prompt": "This agent can answer questions related to merchants aggregated data such as total sales for the last 12 month (year), month, daily. and average chargeback, total decline transactions",
        "endpoint": f"http://{MERCH_ALB_DNS}{MCP_PATH}"
    },
    "transaction_agent": {
        "prompt": "This agent can answer questions related to raw transactions that the merchant process such as authorizations and settlements data but it can't answer questions about merchant aggregated data such average, total , min, max transactions",
        "endpoint": f"http://{TRANS_ALB_DNS}{MCP_PATH}"
    },
    "internet_agent": {
        "prompt": "This agent answer questions about online data related to the merchant such as- perform online searches and fetch different website sites content. for online search use the brave_web_search tool, for fetching a specific web page use the fetch tool",
        "endpoint": [
            f"http://{SEARCH_ALB_DNS}/sse",
            f"http://{FETCH_ALB_DNS}/sse"
        ]
    }
}

def call_agent(endpoint, system_prompt, query):
    # Bedrock model configuration
    bedrock_model = BedrockModel(
        model_id=MODEL_ID,
        temperature=0.3,
        streaming=True,
    )

    # Connect to MCP client
    try:
        if isinstance(endpoint, str):
            mcp_client = MCPClient(lambda: streamablehttp_client(endpoint))
            with mcp_client:
                tools = mcp_client.list_tools_sync()
                agent = Agent(
                    model=bedrock_model,
                    tools=tools,
                    system_prompt=system_prompt
                )
                response = agent(query)

        else:
            # Multiple endpoints
            # mcp_client_search = MCPClient(lambda: streamablehttp_client(endpoint[0]))
            mcp_client_search = MCPClient(lambda: sse_client(endpoint[0]))
            # mcp_client_fetch = MCPClient(lambda: streamablehttp_client(endpoint[1]))
            mcp_client_fetch = MCPClient(lambda: sse_client(endpoint[1]))
            # Use both clients in a single with statement
            with mcp_client_search, mcp_client_fetch:
                # Get tools from both clients
                search_tools = mcp_client_search.list_tools_sync()
                fetch_tools = mcp_client_fetch.list_tools_sync()
                
                # Combine tools
                all_tools = search_tools + fetch_tools
                print("following prompt: {0}".format(system_prompt))
                # Create agent with combined tools
                agent = Agent(
                    model=bedrock_model,
                    tools=all_tools,
                    system_prompt=system_prompt
                )
                response = agent(query)
                
        if hasattr(response, 'content'):
            return response.content
        elif hasattr(response, 'text'):
            return response.text
        elif hasattr(response, 'message'):
            return response.message
        else:
            # if it's a string or already serializable, return as is
            return str(response)
    except ValidationError as ve:
        logger.error("Validation error while processing MCP response", exc_info=True)
        raise ve  # or return a fallback message / raise custom error            
    except Exception as e:
        logger.warning(f"Error occurred: {str(e)}")
        raise e

def format_response(event: Dict[str, Any], status_code: int, body: Any) -> Dict[str, Any]:
    """Helper function to format Lambda response"""
    
    # Ensure body is JSON serializable
    if isinstance(body, str):
        response_text = body
    else:
        response_text = json.dumps(body) if body else ""
    
    response_body = {
        'application/json': {
            'body': response_text
        }
    }

    action_response = {
        'actionGroup': event['actionGroup'],
        'apiPath': event['apiPath'],
        'httpMethod': event['httpMethod'],
        'httpStatusCode': status_code,
        'responseBody': response_body
    }

    session_attributes = event.get('sessionAttributes', {})
    prompt_session_attributes = event.get('promptSessionAttributes', {})
    api_response = {
        'messageVersion': '1.0', 
        'response': action_response,
        'sessionAttributes': session_attributes,
        'promptSessionAttributes': prompt_session_attributes
    }

    return api_response


def parse_properties(event):
    parameters = {}

    for prop in event.get('parameters', []):
        parameters[prop.get('name')] = prop.get('value')

    for prop in event.get('requestBody', {}).get('content', {}).get('application/json', {}).get('properties', []):
        parameters[prop.get('name')] = prop.get('value')

    logger.info(f"Parsed parameters: {parameters}")
    return parameters


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler function for Bedrock action group
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Parse the request event
        action_group = event.get('actionGroup')
        operation = event.get('apiPath')
        properties = parse_properties(event)

        ag_details = ACTION_GROUP_DETAIL.get(operation)
        if not ag_details:
            return format_response(event, 400, {'error': f'Unknown operation: {operation}'})
            
        system_prompt = ag_details.get('prompt')
        endpoint = ag_details.get('endpoint')
        query = properties.get('query')
        
        if not query:
            return format_response(event, 400, {'error': 'Query parameter is required'})

        logger.info(f"Calling agent with endpoint: {endpoint}, query: {query}")
        response = call_agent(endpoint, system_prompt, query)
        logger.info(f"Agent response type: {type(response)}")
        
        return format_response(event, 200, response)

    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {str(e)}")
        return format_response(event, 400, {'error': 'Invalid JSON in request body'})
    
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return format_response(event, 500, {'error': f'Internal server error: {str(e)}'})