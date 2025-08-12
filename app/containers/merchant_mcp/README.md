<!-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. -->
<!-- SPDX-License-Identifier: MIT-0 -->

# Merchant MCP Resource

## Overview
The Merchant MCP server provides tools to query merchant information and statistics from the fraud detection system

## Available Tools

### get_merchant_details(merchant_number: str)

- Retrieves merchant details by ID

#### Input Parameters:

- merchant_number: Merchant Number (e.g., "MRCH2885")

#### Returns - Output Parameters:

- merchant_number: Primary identifier for the merchant
- affiliate_address_line1: First line of affiliate address
- affiliate_address_line2: Second line of affiliate address
- affiliate_city: City of affiliate
- affiliate_name: Name of affiliated organization
- affiliate_state: State of affiliate
- billing_address_line1: First line of billing address
- billing_address_line2: Second line of billing address
- billing_attention: Billing contact person
- billing_city: City for billing
- billing_county: County for billing
- billing_name: Name on billing account
- billing_phone: Billing contact phone
- billing_state: State for billing
- billing_zip_code: ZIP code for billing
- business_contact_name: Primary business contact
- business_email: Business email address
- business_phone_line1: Primary business phone
- business_name: Registered business name
- business_pin: Business PIN number
- business_zip_code: Business ZIP code
- business_address_line1: Business street address
- business_city: Business city
- legal_contact_name: Legal contact person
- legal_phone_line1: Legal contact phone
- legal_name: Legal business name
- country_code: Three-letter country code
- customer_contact: Customer service contact
- email_address: Primary email address
- merchant_category_code: Four-digit MCC code
- merchant_category_description: Description of merchant category
- merchant_id_status: Current merchant status
- merchant_phone: Merchant contact phone
- merchant_zip_code: Merchant ZIP code
- number_of_outlets: Number of business locations
- outlet_name: Name of primary outlet
- outlets_count: Total count of outlets
- security_code: Security identification code
- standard_industrial_classification: SIC description
- sic_code: Standard Industrial Classification code
- exclusion_indicator: Exclusion status flag
- account_status: Current account status
- chain_agent: Chain agent identifier
- chain_bank: Associated bank for chain
- chain_business: Chain business identifier
- chain_code: Chain classification code
- chain_name: Name of chain affiliation
- points_credit_limit: Credit limit for points
- points_cumulative_credit_limit: Cumulative credit limit
- points_sales_limit: Sales limit for points
- signature_amount: Signature requirement amount
- signature_volume: Signature transaction volume
- tmf_match_indicator: Terminated Merchant File indicator
- first_post_date: Date of first posting
- installation_date: System installation date
- last_cancel_date: Most recent cancellation date
- last_post_date: Most recent posting date
- last_status_date: Last status update date
- last_settlement_date: Most recent settlement date
- nach_date: National Automated Clearing House date
- prior_last_post_date: Previous last posting date
- prior_dda_change_date: Previous account change date
- business_address_change_date: Last address change date
- business_phone_change_date: Last phone change date
- business_email_change_date: Last email change date
- created_at: Record creation timestamp
- updated_at: Last update timestamp

### filter_merchant_stats(merchant_number: str, stat_period: str, metric_type: str)

- Filter merchant statistics based on period and metric type

#### Input Parameters:

- merchant_number: Merchant number (e.g., "MRCH2885")
- stat_date: Time Period ("Day", "Month", "Year")
- metric_type: Type of metrics ("sales", "disputes", "authorizations", "all")

#### Returns - Output Parameters:

- merchant_number: Merchant identifier
- stat_date: Period of the statistics
- credit_sales_count: Number of credit card sales
- credit_sales_volume: Total credit sales amount
- credit_sales_average_ticket: Average credit transaction amount
- credit_refunds_count: Number of credit refunds
- credit_refunds_volume: Total refund amount
- credit_refunds_average_ticket: Average refund amount
- credit_refunds_percent: Percentage of sales refunded
- credit_disputes_count: Number of disputes
- credit_disputes_volume: Total disputed amount
- credit_disputes_average_ticket: Average disputed amount
- credit_disputes_percent: Percentage of sales disputed
- credit_reversals_count: Number of reversals
- credit_reversals_volume: Total reversed amount
- credit_reversals_percent: Percentage of sales reversed
- entry_method_keyed_percent: Manual key entry percentage
- entry_method_ecomm_percent: E-commerce transaction percentage
- entry_method_chipped_percent: EMV chip transaction percentage
- entry_method_swiped_percent: Magnetic stripe percentage
- authorizations_count: Total authorization attempts
- authorizations_volume: Total authorization amount
- authorizations_declines_count: Number of declined authorizations
- authorizations_declines_volume: Total declined amount
- authorizations_declines_percent: Decline rate percentage
- forced_sales_count: Number of forced sales
- forced_sales_volume: Total forced sale amount
- forced_sales_average_ticket: Average forced sale amount
- forced_sales_percent: Percentage of forced sales
- debit_sales_count: Number of debit transactions
- debit_sales_volume: Total debit sale amount
- debit_sales_average_ticket: Average debit transaction amount
- debit_refunds_count: Number of debit refunds
- debit_refunds_volume: Total debit refund amount
- debit_refunds_average_ticket: Average debit refund amount
- debit_disputes_count: Number of debit disputes
- debit_disputes_volume: Total debit disputed amount
- debit_disputes_percent: Percentage of debit disputes

### get_merchant_stats(merchant_number: str, stat_date: str)

- Get merchant statistics for a specific period

#### Input Parameters:

- merchant_number: Merchant number (e.g., "MRCH2885")
- stat_date: Period to retrieve stats for ("Day", "Month", "Year")

#### Returns - Output Parameters:

- merchant_number: Merchant identifier
- stat_date: Period of the statistics
- credit_sales_count: Number of credit card sales
- credit_sales_volume: Total credit sales amount
- credit_sales_average_ticket: Average credit transaction amount
- credit_refunds_count: Number of credit refunds
- credit_refunds_volume: Total refund amount
- credit_refunds_average_ticket: Average refund amount
- credit_refunds_percent: Percentage of sales refunded
- credit_disputes_count: Number of disputes
- credit_disputes_volume: Total disputed amount
- credit_disputes_average_ticket: Average disputed amount
- credit_disputes_percent: Percentage of sales disputed
- credit_reversals_count: Number of reversals
- credit_reversals_volume: Total reversed amount
- credit_reversals_percent: Percentage of sales reversed
- entry_method_keyed_percent: Manual key entry percentage
- entry_method_ecomm_percent: E-commerce transaction percentage
- entry_method_chipped_percent: EMV chip transaction percentage
- entry_method_swiped_percent: Magnetic stripe percentage
- authorizations_count: Total authorization attempts
- authorizations_volume: Total authorization amount
- authorizations_declines_count: Number of declined authorizations
- authorizations_declines_volume: Total declined amount
- authorizations_declines_percent: Decline rate percentage
- forced_sales_count: Number of forced sales
- forced_sales_volume: Total forced sale amount
- forced_sales_average_ticket: Average forced sale amount
- forced_sales_percent: Percentage of forced sales
- debit_sales_count: Number of debit transactions
- debit_sales_volume: Total debit sale amount
- debit_sales_average_ticket: Average debit transaction amount
- debit_refunds_count: Number of debit refunds
- debit_refunds_volume: Total debit refund amount
- debit_refunds_average_ticket: Average debit refund amount
- debit_disputes_count: Number of debit disputes
- debit_disputes_volume: Total debit disputed amount
- debit_disputes_percent: Percentage of debit disputes

### search_merchants(business_name: Optional[str] = None, category_code: Optional[str] = None, page: int = 1, page_size: int = 10, status: Optional[str] = None)

- Search merchants with pagination

#### Input Parameters:

- business_name: Business name to search
- category_code: Merchant category code
- page: Page number (default: 1)
- page_size: Results per page (default: 10)
- status: Merchant status filter

#### Returns - Output Parameters:

- items: Array of merchant records containing all fields from merchant_details table
- total: Total number of matching records
- page: Current page number
- page_size: Number of records per page
- Each merchant record includes all fields as defined in get_merchant_details

### filter_data(merchant_number: str, field: str)

- Filter merchant data to retrieve specific field values

#### Input Parameters:

- merchant_number: Merchant identification number (format: MRCH####)
- field: Field name to retrieve - options include:
    - Business_Name, Business_City, Business_State, Business_Contact_Name
    - Business_Email, Business_Phone_Line1, Billing_County, Billing_City
    - Billing_Name, Merchant_Category_Code, Merchant_ID_Status
    - Merchant_Zip_Code, Account_Status, Affiliate_Address_Line1
    - Affiliate_Address_Line2, Chain_Business, Chain_Name
    - Legal_Contact_Name, Legal_Name, First_Post_Date
    - Last_Post_Date, Installation_Date, Created_At, Updated_At

#### Returns - Output Parameters:
json
{
    "field_value": "SPORTS STORE"
}


### get_recent_chargebacks(merchant_number: str, stat_date: str)

- Retrieve recent chargeback data for current day, month or year

#### Input Parameters:

- merchant_number: Merchant identification number (format: MRCH####)

#### Returns - Output Parameters:
json
{
    "raw_response": {
        "merchant_number": "MRCH0000000XX",
        "bucket_date": "Year",
        "credit_disputes_count": 3,
        "credit_disputes_volume": "450.00",
        "credit_disputes_average_ticket": "150.00",
        "credit_disputes_percent": "1.25",
        "debit_disputes_count": 1,
        "debit_disputes_volume": "75.00",
        "debit_disputes_percent": "0.5"
    }
}


### get_refund_summary(merchant_number: str)

- Retrieve comprehensive refund analysis for the last Year

#### Input Parameters:

- merchant_number: Merchant identification number (format: MRCH####)

#### Returns - Output Parameters:
json
{
    "summary": {
        "total_refunds": 150,
        "total_volume": "15000.00",
        "average_refund": "100.00"
    },
    "details": {
        "credit": {
            "count": 125,
            "volume": "13500.00",
            "percent": "5.4"
        },
        "debit": {
            "count": 25,
            "volume": "1500.00",
            "percent": "2.1"
        }
    }
}

### Error Responses

- All error responses follow this format:
json
{
    "error": "Error description message",
    "status_code": 404
}

### Common status codes:

- 400: Bad request
- 404: Not found
- 500: Server error
- 503: Service unavailable

### Usage Examples

#### Get merchant details
merchant = await get_merchant_details("MRCH2885")


#### Get merchant stats
stats = await get_merchant_stats(
    merchant_number="MRCH2885",
    stat_date="Daily"
)

#### Get merchant statistics for specific period
stats = await filter_merchant_stats(
    merchant_number="MRCH2885",
    stat_period="Daily",
    metric_type="all"
)

#### Filter specific merchant field
filtered = await filter_data(
    merchant_number="MRCH2885",
    field="Business_Name"
)

#### Search merchants
merchants = await search_merchants(
    business_name="SPORTS",
    category_code="5655",
    page=1,
    page_size=10
)