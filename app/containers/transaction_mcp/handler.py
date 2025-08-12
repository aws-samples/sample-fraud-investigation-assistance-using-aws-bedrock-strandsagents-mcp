# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os
import logging
import json
import uuid
from typing import TypedDict, List, Union, Dict, Any, Optional
from dotenv import load_dotenv
import httpx

from fastmcp import FastMCP, Context
from starlette.middleware import Middleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.middleware.cors import CORSMiddleware
from starlette.responses import PlainTextResponse
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware
from typing import Annotated, Literal
from pydantic import Field
from tools_description import TransactionToolDescriptions

"""
Transaction MCP Handler

This server provides authorization transaction data and settlement transaction data retrieval tools via FastMCP
It connects to an API Gateway to fetch transaction information
"""

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

async def dual_log(message, logger, ctx):
    logger.info(message)
    await ctx.info(message)

# Load environment variables from .env file
if not os.getenv("API_GATEWAY_BASE_URL"): 
    logger.info("API_GATEWAY_BASE_URL environment variable set by ECS")
    load_dotenv()

# Required environment variables
API_GATEWAY_BASE_URL = os.getenv("API_GATEWAY_BASE_URL")
API_KEY = os.getenv("API_KEY")  # Optional for authentication

if not API_GATEWAY_BASE_URL:
    raise ValueError("API_GATEWAY_BASE_URL environment variable not set")

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = str(uuid.uuid4())
        
        # Read and log the request body
        body = await request.body()
        
        # Log comprehensive request details
        logger.info(f"=== REQUEST {request_id} START ===")
        logger.info(f"Method: {request.method}")
        logger.info(f"URL: {request.url}")
        logger.info(f"Path: {request.url.path}")
        logger.info(f"Query: {request.url.query}")
        logger.info(f"Headers: {dict(request.headers)}")
        logger.info(f"Body length: {len(body)}")
        if body:
            try:
                body_str = body.decode('utf-8')
                logger.info(f"Body content: {body_str[:3000]}...")  # First 1000 chars
            except:
                logger.info(f"Body (raw): {body[:300]}...")
        
        # Recreate request with body for downstream processing
        async def receive():
            return {"type": "http.request", "body": body}
        
        request._receive = receive
        
        # Process the request
        try:
            response = await call_next(request)
            logger.info(f"=== REQUEST {request_id} RESPONSE ===")
            logger.info(f"Status: {response.status_code}")
            logger.info(f"Headers: {dict(response.headers)}")
            logger.info(f"=== REQUEST {request_id} END ===")
            return response
        except Exception as e:
            logger.warning(f"=== REQUEST {request_id} ERROR ===")
            logger.warning(f"Error: {str(e)}")
            logger.warning(f"=== REQUEST {request_id} END ===")
            raise

# Initialize FastMCP server
mcp_server = FastMCP(name="FraudAIAgentTool", stateless_http=True)

@mcp_server.custom_route("/healthz", methods=["GET"])
async def healthz(request: Request):
    return PlainTextResponse("ok", status_code=200)

@mcp_server.custom_route("/health", methods=["GET"])
async def health_check(request: Request):
    """Health check endpoint for the MCP server"""
    return PlainTextResponse("OK", status_code=200)

@mcp_server.resource("file://README.md", mime_type="text/markdown")
async def get_transaction_resource(ctx: Context=None) -> str:
    """
    Provides documentation about transaction tools structure and API usage
    """
    try:
        readme_path = os.path.join("/app", "README.md")
        with open(readme_path, "r", encoding='utf-8') as f:
            content = f.read()
            return content
    except FileNotFoundError as e:
        await dual_log(f"get_transaction_resource - FileNotFoundError: {str(e)}", logger, ctx)
        return f"get_transaction_resource - FileNotFoundError: {str(e)}"
    except PermissionError as e:
        await dual_log(f"get_transaction_resource - PermissionError: {str(e)}", logger, ctx)
        return f"get_transaction_resource - PermissionError: {str(e)}"
    except Exception as e:
        await dual_log(f"get_transaction_resource - Unexpected error: {str(e)}", logger, ctx)
        return f"get_transaction_resource - Unexpected error: {str(e)}"

class AuthorizationTransactionResponse(TypedDict):
    id: int
    merchant_number: str
    account_number: str
    amount: str
    currency: str
    transaction_type: str
    payment_method: str
    card_expiry_date: str
    auth_code: str
    transaction_datetime: str
    approval_status: str
    decline_reason: Union[str, None]
    created_at: str
    updated_at: str

@mcp_server.tool(name='get_authorization_transaction_by_id', description=TransactionToolDescriptions.GET_AUTHORIZATION_TRANSACTION_BY_ID)
async def get_authorization_transaction_by_id(
    auth_transaction_id: Annotated[Union[str, int], Field(description="Unique identifier for the authorization transaction")],
    ctx: Context
) -> AuthorizationTransactionResponse:
    """
    Retrieves authorization transaction information by transaction ID
    
    Args:
        auth_transaction_id: Unique identifier for the authorization transaction
        
    Returns:
        Transaction details or error information
    """
    auth_transaction_id = str(auth_transaction_id)
    
    await dual_log(f"MCP Tool (get_authorization_transaction_by_id) with auth_transaction_id: {auth_transaction_id}", logger, ctx)

    payload = {"auth_transaction_id": auth_transaction_id}

    try:
        result = await call_api_gateway("/api/transaction/authorization", payload, ctx)

        if not result.get("item"):
            raise APIGatewayError(404, f"Transaction {auth_transaction_id} not found")
        
        await dual_log(f"MCP Server: get_authorization_transaction_by_id result: {result}", logger, ctx)

        return result.get("item")
    
    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code}

    except Exception as e:
        await dual_log(f"MCP Tool Error for get_authorization_transaction_by_id: {str(e)}", logger, ctx)
        return {"error": f"Unexpected tool error (get_authorization_transaction_by_id): {str(e)}"}

class SettlementTransactionResponse(TypedDict):
    id: int
    merchant_number: str
    account_number: str
    same_card: str
    transaction_date: str
    processed_amount: str
    auth_amount: str
    tran_id: str
    transaction_type: str
    transaction_status: str
    card_issue_type: str
    transaction_mode: str
    payment_method: str
    auth_code: str
    auth_date: str
    card_class: str
    created_at: str
    updated_at: str

@mcp_server.tool(name='get_settlement_transaction_by_id', description=TransactionToolDescriptions.GET_SETTLEMENT_TRANSACTION_BY_ID)
async def get_settlement_transaction_by_id(
    settlement_transaction_id: Annotated[Union[str, int], Field(description="Unique identifier for the settlement transaction")],
    ctx: Context
) -> SettlementTransactionResponse:
    """
    Retrieves settlement transaction information by transaction ID
    
    Args:
        settlement_transaction_id: Unique identifier for the settlement transaction
        
    Returns:
        Transaction details or error information
    """
    settlement_transaction_id = str(settlement_transaction_id)

    await dual_log(f"MCP Tool (get_settlement_transaction_by_id) with settlement_transaction_id: {settlement_transaction_id}", logger, ctx)

    payload = {"settlement_transaction_id": settlement_transaction_id}

    try:
        result = await call_api_gateway("/api/transaction/settlement", payload, ctx)

        if not result.get("item"):
            raise APIGatewayError(404, f"Transaction {settlement_transaction_id} not found")
        
        await dual_log(f"MCP Server: get_settlement_transaction_by_id result: {result}", logger, ctx)

        return result.get("item")
    
    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code}
    
    except Exception as e:
        await dual_log(f"MCP Tool Error for get_settlement_transaction_by_id: {str(e)}", logger, ctx)
        return {"error": f"Unexpected tool error (get_settlement_transaction_by_id): {str(e)}"}

class TransactionsByMerchantResponse(TypedDict):
    item: List[Union[AuthorizationTransactionResponse, SettlementTransactionResponse]]

@mcp_server.tool(name='get_transactions_by_merchant', description=TransactionToolDescriptions.GET_TRANSACTIONS_BY_MERCHANT)
async def get_transactions_by_merchant(
    merchant_number: Annotated[str, Field(description="Merchant identification number", pattern=r'^MRCH\d+$')],
    transaction_type: Annotated[
        Literal["authorization", "settlement"],
        Field(description="Type of transaction to retrieve either authorization or settlement")
    ] = "authorization",
    date_from: Annotated[Optional[str], Field(description="Start date in YYYY-MM-DD format")] = None,
    date_to: Annotated[Optional[str], Field(description="End date in YYYY-MM-DD format")] = None,
    ctx: Context = None
) -> TransactionsByMerchantResponse:
    """
    Get all transactions for a specific merchant with optional date range
    """
    await dual_log(f"MCP Tool (get_transactions_by_merchant) for {merchant_number}", logger, ctx)
    
    endpoint = "/api/transaction/authorization" if transaction_type == "authorization" else "/api/transaction/settlement"
    payload = {
        "merchant_number": merchant_number,
        "date_from": date_from,
        "date_to": date_to
    }
    
    try:
        result = await call_api_gateway(endpoint, payload, ctx)

        if not result.get("item"):
            raise APIGatewayError(404, f"Transaction for {merchant_number} not found")
        
        await dual_log(f"MCP Server: get_transactions_by_merchant result: {result}", logger, ctx)

        return result.get("item")

    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code}

class RecentTransactionsResponse(TypedDict):
    items: List[Union[AuthorizationTransactionResponse, SettlementTransactionResponse]]
    summary: Dict[str, int]  # {"total_returned": int, "total_available": int}

@mcp_server.tool(name='get_recent_transactions', description=TransactionToolDescriptions.GET_RECENT_TRANSACTIONS)
async def get_recent_transactions(
    merchant_number: Annotated[str, Field(description="Merchant identification number", pattern=r'^MRCH\d+$')],
    transaction_type: Annotated[
        Literal["authorization", "settlement"],
        Field(description="Type of transaction to retrieve either authorization or settlement")
    ] = "authorization",
    limit: Annotated[int, Field(description="Number of transactions to retrieve", ge=1, le=100)] = 5,
    ctx: Context = None
) -> RecentTransactionsResponse:
    """
    Get recent transactions for a merchant using existing apig endpoint
    
    Args:
        merchant_number: Merchant number
        transaction_type: Type of transaction (default to "authorization")
        limit: Number of transactions to retrieve (default to 5)
        
    Returns:
        Dictionary with items or error information
    """

    await dual_log(f"MCP Tool (get_recent_transactions) for {merchant_number}", logger, ctx)

    try:        
        # Use existing API Gateway endpoint
        endpoint = "/api/transaction/authorization" if transaction_type == "authorization" else "/api/transaction/settlement"
        payload = {
            "merchant_number": merchant_number,
            "transaction_type": transaction_type,
            "limit": limit
        }
        result = await call_api_gateway(endpoint, payload, ctx)

        await dual_log(f"MCP Server: get_recent_transactions result: {result}", logger, ctx)

        transactions = result.get("item") if result.get("item") else result.get("items", [])
        if not transactions:
            raise APIGatewayError(404, f"No transactions found for merchant {merchant_number}")
            
        # Filter and limit the results
        sorted_transactions = sorted(
            transactions,
            key=lambda x: x.get('transaction_datetime', ''),
            reverse=True
        )[:limit]

        return {
            "items": sorted_transactions,
            "summary": {
                "total_returned": len(sorted_transactions),
                "total_available": len(transactions)
            }
        }

    except Exception as e:
        await dual_log(f"MCP Tool Error for get_recent_transactions: {str(e)}", logger, ctx)
        return {"error": f"Error in get_recent_transactions: {str(e)}"}
    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code, "items": []}

class FilteredTransactionsResponse(TypedDict):
    items: List[Union[AuthorizationTransactionResponse, SettlementTransactionResponse]]
    count: int

@mcp_server.tool(name='filter_transactions', description=TransactionToolDescriptions.FILTER_TRANSACTIONS)
async def filter_transactions(
    field: Annotated[
        Literal[
            "transaction_type",
            "payment_method",
            "approval_status",
            "transaction_status",
            "card_issue_type",
            "transaction_mode",
            "card_country",
            "card_class",
            "amount",
            "currency",
            "auth_code",
            "transaction_datetime",
            "decline_reason"
        ],
        Field(description="Field name to filter on")
    ],
    value: Annotated[str, Field(description="Value to filter by", min_length=1, max_length=100)],
    ctx: Context = None
) -> FilteredTransactionsResponse:
    """
    Filters transactions based on specified criteria
    
    Args:
        field: Field name to filter on (e.g., "amount", "status", "id")
        
    Returns:
        Dictionary with filtered items or error information
    """
    await dual_log(f"MCP Tool (filter_transactions) with field: {field} and value: {value}", logger, ctx)

    payload = {"filter": {"field": field, "value": value}}

    try:
        result = await call_api_gateway("/api/transaction/filter", payload, ctx)

        if not result.get("item"):
            raise APIGatewayError(404, f"Filter transactions not found")
        
        await dual_log(f"MCP Server: filter_transactions result: {result}", logger, ctx)

        return result.get("items")
    
    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code, "items": []}
    except Exception as e:
        await dual_log(f"MCP Tool Error (filter_transaction): {str(e)}", logger, ctx)
        return {"error": f"Unexpected tool error (filter_transaction): {str(e)}", "items": []}
    
async def call_api_gateway(api_path: str, payload: Dict[str, Any], ctx: Context) -> Dict[str, Any]:
    """
    Helper function to make a GET request to deployed API Gateway
    
    Args:
        api_path: API endpoint path (e.g., "/api/transaction")
        payload: Query parameters for the request
        
    Returns:
        JSON response from the API
    """
    url = f"{API_GATEWAY_BASE_URL.rstrip('/')}{api_path}"
    await dual_log(f"MCP Server: API Gateway URL: {url}", logger, ctx)

    headers = {"Content-Type": "application/json"}
    if API_KEY:
        headers["x-api-key"] = API_KEY

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url, params=payload, headers=headers, timeout=30.0)
            
            await dual_log(f"MCP Server: API Gateway response: {response}", logger, ctx)

            response.raise_for_status()
            
            response_json = response.json()
            await dual_log(f"MCP Server: API Gateway response json: {response_json}", logger, ctx)

            return response_json

        except httpx.HTTPStatusError as e:
            await dual_log("MCP Server: Could not parse error from API response", logger, ctx)

            try:
                error_response_json = e.response.json()
                await dual_log(f"MCP Server: Error response json: {error_response_json}", logger, ctx)

                if 'body' in error_response_json and isinstance(error_response_json['body'], str):
                    error_details = json.loads(error_response_json['body']).get('error', error_details)
                elif 'message' in error_response_json:
                    error_details = error_response_json['message']
                elif 'error' in error_response_json:
                    error_details = error_response_json['error']

            except (json.JSONDecodeError, AttributeError):
                error_details = e.response.text
            
            await dual_log(f"MCP Server: API Gateway call to {url} failed with status {e.response.status_code}: {error_details}", logger, ctx)

            raise APIGatewayError(e.response.status_code, error_details)
        except httpx.RequestError as e:
            await dual_log(f"MCP Server: Network error calling API Gateway {url}: {str(e)}", logger, ctx)
            raise APIGatewayError(503, f"Network error calling API Gateway: {str(e)}")

class APIGatewayError(Exception):
    """
    Custom exception for API Gateway errors.
    
    Attributes:
        status_code: HTTP status code from the API response
        error_message: Descriptive error message
    """
    def __init__(self, status_code: int, error_message: str):
        self.status_code = status_code
        self.error_message = error_message
        super().__init__(f"API Gateway Error {status_code}: {error_message}")

if __name__ == "__main__":
    logger.info("Starting Transaction FastMCP server...")
    
    custom_middleware = [
        Middleware(CORSMiddleware, allow_origins=["*"]),
        Middleware(LoggingMiddleware)
    ]
    app = mcp_server.http_app(middleware=custom_middleware)
    app.router.redirect_slashes = False

    mcp_server._http_app = ProxyHeadersMiddleware(app, trusted_hosts="*")
    mcp_server.run(
        transport="streamable-http", 
        host="0.0.0.0",     # nosec B104 # Otherwise will use "127.0.0.1"
        port=8080, 
        path="/mcp"
    )