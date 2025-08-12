# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import asyncio
import os
import logging
import json
import uuid
from typing import Dict, Any, Optional, TypedDict, List, Union
from dotenv import load_dotenv
import re
import httpx

from fastmcp import FastMCP, Context
from starlette.middleware import Middleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.middleware.cors import CORSMiddleware
from starlette.responses import PlainTextResponse
from starlette.requests import Request
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware
from typing import Annotated, Literal
from pydantic import Field
from tools_description import MerchantToolDescriptions

"""
Merchant MCP Handler

This server provides merchant data retrieval tools via FastMCP
It connects to an API Gateway to fetch merchant information
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
        # Log request details
        logger.info(f"Request {request_id} started", extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "headers": dict(request.headers)
        })
        # Process the request
        response = await call_next(request)
        # Log response details
        logger.info(f"Request {request_id} completed", extra={
            "request_id": request_id,
            "status_code": response.status_code
        })
        return response

# Initialize FastMCP server
mcp_server = FastMCP("FraudAIAgentTool", stateless_http=True)

@mcp_server.custom_route("/healthz", methods=["GET"])
async def healthz(request: Request):
    return PlainTextResponse("ok", status_code=200)

@mcp_server.custom_route("/health", methods=["GET"])
async def health_check(request: Request):
    return PlainTextResponse("OK", status_code=200)

@mcp_server.resource("file://README.md", mime_type="text/markdown")
async def get_merchant_resource(ctx: Context = None) -> str:
    """
    Provides documentation about merchant tools structure and API usage
    """
    try:
        readme_path = os.path.join("/app", "README.md")
        with open(readme_path, "r", encoding='utf-8') as f:
            content = f.read()
            return content
    except FileNotFoundError as e:
        await dual_log(f"get_merchant_resource - FileNotFoundError: {str(e)}", logger, ctx)
        return f"get_merchant_resource - FileNotFoundError: {str(e)}"
    except PermissionError as e:
        await dual_log(f"get_merchant_resource - PermissionError: {str(e)}", logger, ctx)
        return f"get_merchant_resource -PermissionError: {str(e)}"
    except Exception as e:
        await dual_log(f"get_merchant_resource - Unexpected error: {str(e)}", logger, ctx)
        return f"get_merchant_resource - Unexpected error: {str(e)}"

class MerchantStatsResponse(TypedDict):
    id: int
    merchant_number: str
    bucket_date: str
    credit_sales_count: int
    credit_sales_volume: str
    credit_sales_average_ticket: str
    credit_refunds_count: int
    credit_refunds_volume: str
    credit_refunds_average_ticket: str
    credit_refunds_percent: str
    credit_disputes_count: int
    credit_disputes_volume: str
    credit_disputes_average_ticket: str
    credit_disputes_percent: str
    credit_reversals_count: int
    credit_reversals_volume: str
    credit_reversals_percent: str
    entry_method_keyed_percent: str
    entry_method_ecomm_percent: str
    entry_method_chipped_percent: str
    entry_method_swiped_percent: str
    authorizations_count: int
    authorizations_volume: str
    authorizations_declines_count: int
    authorizations_declines_volume: str
    authorizations_declines_percent: str
    debit_sales_count: int
    debit_sales_volume: str
    debit_sales_average_ticket: str
    debit_refunds_count: int
    debit_refunds_volume: str
    debit_refunds_average_ticket: str
    debit_disputes_count: int
    debit_disputes_volume: str
    debit_disputes_percent: str
    created_at: str
    updated_at: str
 
@mcp_server.tool(name='get_merchant_stats', description=MerchantToolDescriptions.GET_MERCHANT_STATS)
async def get_merchant_stats(
    merchant_number: Annotated[str, Field(description="Merchant number to get statistics for", pattern=r'^MRCH\d+$')],
    stat_date: Annotated[
        Literal["Day", "Month", "Year"],
        Field(description="Time period for stats")
    ] = "Day",
    ctx: Context = None
) -> MerchantStatsResponse:
    """
    Retrieves merchant statistics for a specific date
    
    Args:
        merchant_number: Merchant number to get statistics for
        stat_date: Date to get statistics for
        
    Returns:
        Merchant statistics or error information
    """
    await dual_log(f"MCP Tool (get_merchant_stats) with merchant_number: {merchant_number}", logger, ctx)

    payload = {"merchant_number": merchant_number, "stat_date": stat_date}
    try:
        result = await call_api_gateway("/api/merchant/stats", payload, ctx)

        if not result.get("item"):
            raise APIGatewayError(404, f"Merchant stats for {merchant_number} not found")
        
        await dual_log(f"MCP Server: get_merchant_stats result: {result}", logger, ctx)
        
        return result.get("item")
    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code}

    except Exception as e:
        await dual_log(f"MCP Tool Error for get_merchant_stats: {str(e)}", logger, ctx)
        return {"error": f"Unexpected tool error (get_merchant_stats): {str(e)}"}

class FilteredStatsResponse(TypedDict):
    credit_sales_count: int
    credit_sales_volume: str
    credit_sales_average_ticket: str
    credit_refunds_count: int
    credit_refunds_volume: str
    credit_refunds_average_ticket: str
    credit_refunds_percent: str
    credit_disputes_count: int
    credit_disputes_volume: str
    credit_disputes_average_ticket: str
    credit_disputes_percent: str
    credit_reversals_count: int
    credit_reversals_volume: str
    credit_reversals_percent: str

@mcp_server.tool(name='filter_merchant_stats', description=MerchantToolDescriptions.FILTER_MERCHANT_STATS)
async def filter_merchant_stats(
    merchant_number: Annotated[str, Field(description="The merchant number to filter stats for", pattern=r'^MRCH\d+$')],
    stat_date: Annotated[
        Literal["Day", "Month", "Year"],
        Field(description="Time period for stats")
    ] = "Daily",
    metric_type: Annotated[str, Field(description="Type of metrics to return (e.g., 'sales', 'disputes', 'authorizations', 'credit', 'debit', 'all')")]="all",
    ctx: Context = None
) -> FilteredStatsResponse:
    """
    Filters merchant statistics based on specified criteria
    
    Args:
        merchant_number: The merchant number to filter stats for
        stat_date: Time period for stats (Day, Month, Year)
        metric_type: Type of metrics to return (sales, disputes, authorizations, all)
        
    Returns:
        Dictionary with filtered statistics or error information
    """
    await dual_log(f"MCP Tool (filter_merchant_stats) with merchant_number: {merchant_number}, period: {stat_date}", logger, ctx)

    payload = {
        "merchant_number": merchant_number,
        "stat_date": stat_date,
        "metric_type": metric_type
    }

    try:
        result = await call_api_gateway("/api/merchant/filter-stats", payload, ctx)

        if not result.get("item"):
            raise APIGatewayError(404, f"Merchant stats not found: {merchant_number}")
        
        await dual_log(f"MCP Server: filter_merchant_stats result: {result}", logger, ctx)

        return result.get("item")
    
    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code}
    except Exception as e:
        await dual_log(f"MCP Tool Error for filter_merchant_stats: {str(e)}", logger, ctx)
        return {"error": f"Unexpected tool error: {str(e)}"}

class SearchMerchantsResponse(TypedDict):
    merchants: List[Dict[str, str]]
    pagination: Dict[str, int]
    
@mcp_server.tool(name='search_merchants', description=MerchantToolDescriptions.SEARCH_MERCHANTS)
async def search_merchants(
    business_name: Annotated[Optional[str], Field(description="Business name to search for", min_length=1, max_length=100)] = None,
    category_code: Annotated[Optional[str], Field(description="Merchant category code", pattern=r'^\d{4}$')] = None,
    page: Annotated[int, Field(description="Page number for pagination", ge=1)] = 1,
    page_size: Annotated[int, Field(description="Number of items per page", ge=1, le=100)] = 10,
    ctx: Context = None
) -> SearchMerchantsResponse:
    """
    Search merchants based on various criteria with pagination
    """
    await dual_log(f"MCP Tool - search_merchants", logger, ctx)
    
    payload = {
        "business_name": business_name,
        "category_code": category_code,
        "page": page,
        "page_size": page_size
    }
    try:
        result = await call_api_gateway("/api/merchant/search", payload, ctx)

        if not result.get("item"):
            raise APIGatewayError(404, f"Merchant details not found")
        
        await dual_log(f"MCP Server: search_merchants result: {result}", logger, ctx)
        
        return result.get("item")
    except APIGatewayError as e:
        await dual_log(f"MCP Tool Error for search_merchants: {str(e)}", logger, ctx)
        return {"error": e.error_message, "status_code": e.status_code}

class MerchantDetailsResponse(TypedDict):
    merchant_number: str
    merchant_name: str
    address_line1: str
    address_line2: Union[str, None]
    county: str
    city: str
    state: str
    billing_address_line1: str
    billing_address_line2: Union[str, None]
    billing_city: str
    billing_county: str
    billing_name: str
    billing_phone: str
    billing_state: str
    billing_zip_code: str
    business_contact_name: Union[str, None]
    business_email: Union[str, None]
    business_phone: str
    business_name: str
    business_zip_code: str
    business_address_line1: str
    business_address_line2: Union[str, None]
    business_city: str
    business_state: str
    legal_contact_name: str
    legal_phone_line1: str
    legal_name: str
    country_code: str
    merchant_category_code: str
    merchant_category_description: str
    merchant_website: Union[str, None]
    merchant_phone: str
    merchant_zip_code: str
    standard_industrial_classification: str
    sic_code: str
    account_status: str
    signature_amount: str
    signature_volume: str
    terminated_indicator: Union[str, None]
    first_post_date: str
    installation_date: str
    last_cancel_date: Union[str, None]
    last_post_date: str
    last_status_date: str
    last_settlement_date: str
    business_address_change_date: Union[str, None]
    business_phone_change_date: Union[str, None]
    business_email_change_date: Union[str, None]
    created_at: str
    updated_at: str

@mcp_server.tool(name='get_merchant_details', description=MerchantToolDescriptions.GET_MERCHANT_DETAILS)
async def get_merchant_details(
    merchant_number: Annotated[str, Field(description="Unique identifier for the merchant", pattern=r'^MRCH\d+$')],
    ctx: Context
) -> MerchantDetailsResponse:
    """
    Retrieves merchant information by merchant number
    
    Args:
        merchant_number: Unique identifier for the merchant
        
    Returns:
        Merchant details or error information
    """
    await dual_log(f"MCP Tool (get_merchant_details) with merchant_number: {merchant_number}", logger, ctx)

    payload = {"merchant_number": merchant_number}
    try:
        result = await call_api_gateway("/api/merchant/details", payload, ctx)

        if not result.get("item"):
            raise APIGatewayError(404, f"Merchant details not found: {merchant_number}")
        
        await dual_log(f"MCP Server: get_merchant_details result: {result}", logger, ctx)
        print(f"MCP Server: get_merchant_details result: {result.get("item")}")
        return result.get("item")
    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code}
    except Exception as e:
        await dual_log(f"MCP Tool Error for get_merchant_details: {str(e)}", logger, ctx)
        return {"error": f"Unexpected tool error: {str(e)}"}
    
class FilteredDataResponse(TypedDict):
    field_value: Any  # This will contain the value of the requested field

@mcp_server.tool(name='filter_data', description=MerchantToolDescriptions.FILTER_DATA)
async def filter_data(
    merchant_number: Annotated[str, Field(description="The merchant number to filter data for", pattern=r'^MRCH\d+$')],
    field: Annotated[
        Literal[
            "Merchant_Name",
            "Business_Name",
            "Business_City",
            "Business_State",
            "Business_Contact_Name",
            "Business_Email",
            "Business_Phone",
            "Billing_County",
            "Billing_City",
            "Billing_Name",
            "Merchant_Category_Code",
            "Account_Status",
            "Merchant_Zip_Code",
            "Address_Line1",
            "Address_Line2",
            "Legal_Contact_Name",
            "Legal_Name",
            "First_Post_Date",
            "Last_Post_Date",
            "Installation_Date",
            "Merchant_Website",
            "Terminated_Indicator",
            "Created_At",
            "Updated_At"
        ],
        Field(description="Field name to filter on")
    ],
    ctx: Context
) -> FilteredDataResponse:
    """
    Filters merchant data based on specified criteria
    
    Args:
        merchant_number: The merchant number to filter data for
        field: Field name to filter on (e.g., "transactions", "revenue")
        
    Returns:
        Dictionary with filtered items or error information
    """

    await dual_log(f"MCP Tool (filter_data) with merchant_number: {merchant_number}", logger, ctx)

    payload = {"merchant_number": merchant_number, "filter": {"field": field}}

    try:
        result = await call_api_gateway("/api/merchant/filter-data", payload, ctx)

        if not result.get("item"):
            raise APIGatewayError(404, f"Merchant details not found: {merchant_number}")
        
        await dual_log(f"MCP Server: filter_data result: {result}", logger, ctx)

        return result.get("item")
    
    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code, "items": []}
    except Exception as e:
        await dual_log(f"MCP Tool Error for filter_data: {str(e)}", logger, ctx)
        return {"error": f"Unexpected tool error: {str(e)}", "items": []}

class ChargebackStatsResponse(TypedDict):
    raw_response: Dict[str, Union[int, str]]

def normalize_stat_date(period: str) -> str:
    """
    Normalize stat period input using regex patterns
    """
    period = period.lower().replace(" ", "")
    
    # Daily patterns
    if re.match(r'^(daily|day|24hours|today)$', period):
        return "Day"
        
    # Monthly patterns
    if re.match(r'^(month|currentmonth|30days)$', period):
        return "Month"
        
    # Yearly patterns
    if re.match(r'^(year|12months|12month|1year|annual|twelve)$', period):
        return "Year"
        
    return "Day"  # default

@mcp_server.tool(name='get_recent_chargebacks', description=MerchantToolDescriptions.GET_RECENT_CHARGEBACKS)
async def get_recent_chargebacks(
    merchant_number: Annotated[str, Field(description="Merchant number to get chargebacks for", pattern=r'^MRCH\d+$')],
    stat_date: Annotated[str, Field(description="Time period for stats (Day, Month, Year)")] = "Day",
    ctx: Context = None
) -> ChargebackStatsResponse:
    """
    Get recent chargebacks using existing filter_merchant_stats
    
    Args:
        merchant_number: Merchant number
        
    Returns:
        Dictionary with items or error information
    """
    await dual_log(f"MCP Tool (get_recent_chargebacks) for {merchant_number}", logger, ctx)

    try:
        # Normalize the stat period
        normalized_period = normalize_stat_date(stat_date)
        print("For period: {0}".format(normalized_period))

        # Get primary stats
        payload = {
            "merchant_number": merchant_number,
            "stat_date": normalized_period,
            "metric_type": "disputes"
        }

        result = await call_api_gateway("/api/merchant/filter-stats", payload, ctx)

        await dual_log(f"MCP Server: get_recent_chargebacks for {normalized_period} result: {result}", logger, ctx)

        if not result.get("item"):
            raise APIGatewayError(404, f"Chargeback stats not found for merchant {merchant_number}")
        
        response = {
            "raw_response" : result.get("item", {}),
        }

        return response

    except Exception as e:
        await dual_log(f"MCP Tool Error for get_recent_chargebacks: {str(e)}", logger, ctx)
        return {"error": f"Error in get_recent_chargebacks: {str(e)}"}
    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code, "items": []}

class RefundSummaryResponse(TypedDict):
    summary: Dict[str, Union[int, str]]
    details: Dict[str, Dict[str, Union[int, str]]]
    
@mcp_server.tool(name='get_refund_summary', description=MerchantToolDescriptions.GET_REFUND_SUMMARY)
async def get_refund_summary(
    merchant_number: Annotated[str, Field(description="Merchant number to get refund summary for", pattern=r'^MRCH\d+$')],
    stat_date: Annotated[str, Field(description="Time period for stats (Day, Month, Year)")] = "Day",
    ctx: Context = None
) -> RefundSummaryResponse:
    """
    Get refund summary using existing filter_merchant_stats
    
    Args:
        merchant_number: Merchant number
        
    Returns:
        Dictionary with items or error information
    """
    await dual_log(f"MCP Tool (get_refund_summary) for {merchant_number}", logger, ctx)

    try:
        # Normalize the stat period
        normalized_period = normalize_stat_date(stat_date)

        payload = {
            "merchant_number": merchant_number,
            "stat_date": normalized_period,
            "metric_type": "refunds"
        }
        
        # Use existing API Gateway endpoint
        result = await call_api_gateway("/api/merchant/filter-stats", payload, ctx)

        await dual_log(f"MCP Server: get_refund_summary for {normalized_period} result: {result}", logger, ctx)
        
        if not result.get("item"):
            raise APIGatewayError(404, f"Refund stats not found for merchant {merchant_number}")
            
        stats = result.get("item", {})
        
        # Calculate additional metrics
        total_refunds = stats.get("credit_refunds_count", 0) + stats.get("debit_refunds_count", 0)
        total_volume = stats.get("credit_refunds_volume", 0) + stats.get("debit_refunds_volume", 0)
        
        return {
            "summary": {
                "total_refunds": total_refunds,
                "total_volume": total_volume,
                "average_refund": total_volume / total_refunds if total_refunds > 0 else 0
            },
            "details": {
                "credit": {
                    "count": stats.get("credit_refunds_count", 0),
                    "volume": stats.get("credit_refunds_volume", 0),
                    "percent": stats.get("credit_refunds_percent", 0)
                },
                "debit": {
                    "count": stats.get("debit_refunds_count", 0),
                    "volume": stats.get("debit_refunds_volume", 0),
                    "percent": stats.get("debit_refunds_percent", 0)
                }
            }
        }
    
    except Exception as e:
        await dual_log(f"MCP Tool Error for get_refund_summary: {str(e)}", logger, ctx)
        return {"error": f"Error in get_refund_summary: {str(e)}"}
    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code, "items": []}

class DeclineReason(TypedDict):
    reason: str
    count: int

class DeclineAnalysisResponse(TypedDict):
    items: List[DeclineReason]
    summary: Dict[str, int]  # {"total_declines": int, "unique_reasons": int}

@mcp_server.tool(name='get_decline_analysis', description=MerchantToolDescriptions.GET_DECLINE_ANALYSIS)
async def get_decline_analysis(
    merchant_number: Annotated[str, Field(description="Merchant identification number", pattern=r'^MRCH\d+$')],
    date_from: Annotated[str, Field(description="Start date in YYYY-MM-DD format")],
    date_to: Annotated[str, Field(description="End date in YYYY-MM-DD format")],
    ctx: Context = None
) -> DeclineAnalysisResponse:
    """
    Get decline authorization reasons analysis using existing endpoint
    
    Args:
        merchant_number: Merchant number
        date_from: Start date for the date range (format: YYYY-MM-DD)
        date_to: End date for the date range (format: YYYY-MM-DD)
        
    Returns:
        Dictionary with items or error information
    """
    await dual_log(f"MCP Tool (get_decline_analysis) for {merchant_number}", logger, ctx)

    try:
        payload = {
            "merchant_number": merchant_number,
            "transaction_type": "authorization",
            "date_from": date_from,
            "date_to": date_to,
            "approval_status": "Declined"
        }

        endpoint = "/api/transaction/authorization"
        
        result = await call_api_gateway(endpoint, payload, ctx)

        await dual_log(f"MCP Server: get_decline_analysis result: {result}", logger, ctx)

        decline_transactions = result.get("item") if result.get("item") else result.get("items", [])
        if not decline_transactions:
            raise APIGatewayError(404, f"No decline data found for merchant {merchant_number}")
            
        # Process transactions to get decline analysis
        decline_reasons = {}

        for txn in decline_transactions:
            reason = txn.get("decline_reason", "Unknown")
            decline_reasons[reason] = decline_reasons.get(reason, 0) + 1

        if not decline_reasons:
            return {
                "items": [],
                "summary": "No declined transactions found in the specified date range"
            }
                
        analysis = [
            {"reason": reason, "count": count}
            for reason, count in sorted(decline_reasons.items(), key=lambda x: x[1], reverse=True)
        ]
        
        return {
            "items": analysis,
            "summary": {
                "total_declines": sum(decline_reasons.values()),
                "unique_reasons": len(decline_reasons)
            }
        }

    except Exception as e:
        await dual_log(f"MCP Tool Error for get_decline_analysis: {str(e)}", logger, ctx)
        return {"error": f"Error in get_decline_analysis: {str(e)}"}
    except APIGatewayError as e:
        return {"error": e.error_message, "status_code": e.status_code, "items": []}

# Call to API Gateway
async def call_api_gateway(api_path: str, payload: Dict[str, Any], ctx: Context) -> Dict[str, Any]:
    """
    Helper function to make a GET request to deployed API Gateway
    
    Args:
        api_path: API endpoint path (e.g., "/api/merchant")
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
                error_details = "Unknown error"
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
    logger.info("Starting Merchant FastMCP server...")

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
        path="/mcp",
        log_level="debug"
    )
