# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import argparse
import json
import sys
import boto3
import tempfile
import os

def query_bedrock_agent(question, agent_id, agent_alias, region):
    try:
        # Initialize the Bedrock Runtime client
        bedrock_agent = boto3.client(
            service_name='bedrock-agent-runtime',
            region_name=region
        )
        
        # Prepare the request parameters
        request_parameters = {
            "agentId": agent_id,
            "agentAliasId": agent_alias,
            "sessionId": "session-" + str(hash(question))[:8],
            "inputText": question
        }
        
        # Make the request to the agent
        response = bedrock_agent.invoke_agent(**request_parameters)
        
        # Process the event stream to get the response
        full_response = ""
        for event in response["completion"]:
            if "chunk" in event:
                chunk_data = event["chunk"]["bytes"].decode('utf-8')
                full_response += chunk_data

        return {'sessionID': response['sessionId'], 'completion': full_response}
        
    except Exception as e:
        return {'completion': f"Error querying Bedrock agent: {e}"}

def main():
    parser = argparse.ArgumentParser(description="Query an AWS Bedrock agent and get the response")
    parser.add_argument("question", help="The question to ask the agent")
    parser.add_argument("--agent-id", required=True, help="The Bedrock Agent ID")
    parser.add_argument("--agent-alias", required=True, help="The Bedrock Agent Alias ID")
    parser.add_argument("--region", default="us-east-1", help="AWS region (default: us-east-1)")
    parser.add_argument("--output-file", help="Write the response to this file instead of stdout")
    
    args = parser.parse_args()
    
    answer = query_bedrock_agent(
        args.question,
        args.agent_id,
        args.agent_alias,
        args.region
    )
    
    if args.output_file:
        # Ensure directory exists
        os.makedirs(os.path.dirname(args.output_file), exist_ok=True)
        with open(args.output_file, "w+") as f:
            json.dump(answer, f)
    else:
        print(answer)

if __name__ == "__main__":
    main()