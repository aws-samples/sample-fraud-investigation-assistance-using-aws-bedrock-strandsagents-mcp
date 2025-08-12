# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

class MerchantToolDescriptions:
    GET_MERCHANT_STATS = '''
        - Description: Get comprehensive merchant statistics for a specific period
        - Key features:
            * Multiple aggregation period options (Day, Month, Year)
            * Comprehensive credit and debit transaction statistics
            * Detailed breakdown of sales, refunds, disputes, and reversals
            * Entry method distribution analysis
            * Authorization and decline metrics
        - Parameters:
            * merchant_number (required): Merchant identification number (format: MRCH####)
            * stat_date (optional): Time period for stats - "Day", "Month", or "Year" (default: "Day")
        - Returns:
            * id: Unique stats record identifier (int)
            * merchant_number: Merchant identification code (str)
            * stat_date: Date of statistics (str)
            * credit_sales_count: Number of credit sales transactions (int)
            * credit_sales_volume: Total volume of credit sales (str)
            * credit_sales_average_ticket: Average credit sale amount (str)
            * credit_refunds_count: Number of credit refund transactions (int)
            * credit_refunds_volume: Total volume of credit refunds (str)
            * credit_refunds_average_ticket: Average credit refund amount (str)
            * credit_refunds_percent: Percentage of credit refunds (str)
            * credit_disputes_count: Number of credit dispute transactions (int)
            * credit_disputes_volume: Total volume of credit disputes (str)
            * credit_disputes_average_ticket: Average credit dispute amount (str)
            * credit_disputes_percent: Percentage of credit disputes (str)
            * credit_reversals_count: Number of credit reversals (int)
            * credit_reversals_volume: Total volume of credit reversals (str)
            * credit_reversals_percent: Percentage of credit reversals (str)
            * entry_method_keyed_percent: Percentage of keyed entry methods (str)
            * entry_method_ecomm_percent: Percentage of e-commerce entries (str)
            * entry_method_chipped_percent: Percentage of chip card entries (str)
            * entry_method_swiped_percent: Percentage of swiped card entries (str)
            * authorizations_count: Number of authorizations (int)
            * authorizations_volume: Total volume of authorizations (str)
            * authorizations_declines_count: Number of declined authorizations (int)
            * authorizations_declines_volume: Volume of declined authorizations (str)
            * authorizations_declines_percent: Percentage of declined authorizations (str)
            * forced_sales_count: Number of forced sales (int)
            * forced_sales_volume: Total volume of forced sales (str)
            * forced_sales_average_ticket: Average forced sale amount (str)
            * forced_sales_percent: Percentage of forced sales (str)
            * debit_sales_count: Number of debit sales transactions (int)
            * debit_sales_volume: Total volume of debit sales (str)
            * debit_sales_average_ticket: Average debit sale amount (str)
            * debit_refunds_count: Number of debit refund transactions (int)
            * debit_refunds_volume: Total volume of debit refunds (str)
            * debit_refunds_average_ticket: Average debit refund amount (str)
            * debit_disputes_count: Number of debit dispute transactions (int)
            * debit_disputes_volume: Total volume of debit disputes (str)
            * debit_disputes_percent: Percentage of debit disputes (str)
            * created_at: Record creation timestamp (str)
            * updated_at: Record last update timestamp (str)
    '''


    FILTER_MERCHANT_STATS = '''
        - Description: Filter merchant statistics to focus on specific metric types
        - Key features:
            * Targeted statistical data for specific analysis needs
            * Supports various metric types (sales, refunds, disputes, etc.)
            * Multiple time period options
        - Parameters:
            * merchant_number (required): Merchant identification number (format: MRCH####)
            * stat_date (optional): Time period for stats - "Day", "Month", or "Year" (default: "Day")
            * metric_type (optional): Type of metrics to return (default: "all") - options include:
                - credit_sales, credit_refunds, credit_disputes, credit_reversals
                - debit_sales, debit_refunds, debit_disputes
                - authorizations, forced_sales, entry_methods, all
        - Returns:
            * Filtered subset of merchant statistics based on the selected metric_type
            * For example, with metric_type="credit_sales":
                - credit_sales_count: Number of credit sales transactions (int)
                - credit_sales_volume: Total volume of credit sales (str)
                - credit_sales_average_ticket: Average credit sale amount (str)'''

    SEARCH_MERCHANTS = '''
        - Description: Search for merchants based on various criteria with pagination
        - Key features:
            * Flexible search by business name or category code
            * Paginated results for managing large result sets
            * Configurable page size
            * Returns merchant summary information
        - Parameters:
            * business_name (optional): Business name to search for (1-100 characters)
            * category_code (optional): 4-digit merchant category code
            * page (optional): Page number for pagination (minimum: 1, default: 1)
            * page_size (optional): Number of items per page (range: 1-100, default: 10)
        - Returns:
            * merchants: Array of merchant objects, each containing:
                - merchant_number: Unique merchant identifier (str)
                - business_name: Name of the business (str)
                - merchant_category_code: MCC code (str)
                - business_city: City location (str)
                - business_state: State location (str)
                - account_status: Current status of the merchant account (str)
            * pagination: Object containing:
                - total: Total number of matching merchants (int)
                - pages: Total number of pages (int)
                - current_page: Current page number (int)
                - page_size: Number of items per page (int)'''
    
    GET_MERCHANT_DETAILS = '''
        - Description: Retrieve comprehensive merchant profile information
        - Key features:
            * Comprehensive merchant business information
            * Complete address and contact details
            * Account status and merchant categorization
        - Parameters:
            * merchant_number (required): Unique merchant identifier (format: MRCH####)
        - Returns:
            * merchant_number: Unique merchant identifier (str)
            * affiliate_address_line1: Affiliate address line 1 (str)
            * affiliate_address_line2: Affiliate address line 2 (str or null)
            * affiliate_city: Affiliate city (str)
            * affiliate_name: Affiliate name (str)
            * affiliate_state: Affiliate state (str)
            * billing_address_line1: Billing address line 1 (str)
            * billing_address_line2: Billing address line 2 (str)
            * billing_attention: Billing attention name (str)
            * billing_city: Billing city (str)
            * billing_county: Billing county (str)
            * billing_name: Billing name (str)
            * billing_phone: Billing phone number (str)
            * billing_state: Billing state (str)
            * billing_zip_code: Billing postal code (str)
            * business_contact_name: Business contact name (str or null)
            * business_email: Business email address (str or null)
            * business_phone_line1: Business phone number (str)
            * business_name: Business name (str)
            * business_pin: Business PIN number (str or null)
            * business_zip_code: Business postal code (str)
            * business_address_line1: Business address line 1 (str)
            * business_city: Business city (str)
            * legal_contact_name: Legal contact name (str)
            * legal_phone_line1: Legal contact phone number (str)
            * legal_name: Legal business name (str)
            * country_code: Country code (str)
            * customer_contact: Customer contact name (str)
            * email_address: Primary email address (str)
            * merchant_category_code: MCC code (str)
            * merchant_category_description: MCC description (str)
            * merchant_id_status: Merchant ID status (str)
            * merchant_phone: Merchant phone number (str)
            * merchant_zip_code: Merchant postal code (str)
            * number_of_outlets: Number of business outlets (int)
            * outlet_name: Outlet name (str)
            * outlets_count: Count of outlets (int)
            * security_code: Security code (str)
            * standard_industrial_classification: SIC description (str)
            * sic_code: SIC code (str)
            * exclusion_indicator: Exclusion indicator (str)
            * account_status: Current account status (str)
            * chain_agent: Chain agent (str)
            * chain_bank: Chain bank (str)
            * chain_business: Chain business (str)
            * chain_code: Chain code (str)
            * chain_name: Chain name (str)
            * points_credit_limit: Points credit limit (str)
            * points_cumulative_credit_limit: Points cumulative credit limit (str)
            * points_sales_limit: Points sales limit (str)
            * signature_amount: Signature required amount (str)
            * signature_volume: Signature volume (str)
            * tmf_match_indicator: TMF match indicator (str or null)
            * first_post_date: First posting date (str)
            * installation_date: Installation date (str)
            * last_cancel_date: Last cancellation date (str or null)
            * last_post_date: Last posting date (str)
            * last_status_date: Last status change date (str)
            * last_settlement_date: Last settlement date (str)
            * nach_date: NACH date (str)
            * prior_last_post_date: Prior last posting date (str)
            * prior_dda_change_date: Prior DDA change date (str or null)
            * business_address_change_date: Business address change date (str)
            * business_phone_change_date: Business phone change date (str or null)
            * business_email_change_date: Business email change date (str)
            * created_at: Record creation timestamp (str)
            * updated_at: Record last update timestamp (str)'''
    

    FILTER_DATA = '''
        - Description: Filter merchant data to retrieve specific field values
        - Key features:
            * Retrieves individual data points without full merchant profile
            * Supports many important merchant fields
            * Efficient for targeted data retrieval
        - Parameters:
            * merchant_number (required): Merchant identification number (format: MRCH####)
            * field (required): Field name to retrieve - options include:
                - Business_Name, Business_City, Business_State, Business_Contact_Name
                - Business_Email, Business_Phone_Line1, Billing_County, Billing_City
                - Billing_Name, Merchant_Category_Code, Merchant_ID_Status
                - Merchant_Zip_Code, Account_Status, Affiliate_Address_Line1
                - Affiliate_Address_Line2, Chain_Business, Chain_Name
                - Legal_Contact_Name, Legal_Name, First_Post_Date
                - Last_Post_Date, Installation_Date, Created_At, Updated_At
        - Returns:
            * field_value: The requested field value (string, number, or null depending on field type)'''


    GET_RECENT_CHARGEBACKS = '''
        - Description: Retrieve recent chargeback data with daily and monthly comparisons
        - Key features:
            * Current Day, Month or Year aggregated chargeback statistics
            * Comprehensive dispute metrics
            * Trend comparison between periods
            * Total chargeback volume and count summary
        - Parameters:
            * merchant_number (required): Merchant identification number (format: MRCH####)
            * stat_date (required): aggregator period can be either: Day, Month or Year
        - Returns:
            * raw_response: Object containing daily chargeback statistics:
                - merchant_number: the ID of the merchant
                - bucket_date: The aggregated period of the stats - Day, Month, Year
                - credit_disputes_count: Number of credit dispute transactions (int)
                - credit_disputes_volume: Total volume of credit disputes (str)
                - credit_disputes_average_ticket: Average credit dispute amount (str)
                - credit_disputes_percent: Percentage of credit disputes (str)
                - debit_disputes_count: Number of debit dispute transactions (int)
                - debit_disputes_volume: Total volume of debit disputes (str)
                - debit_disputes_percent: Percentage of debit disputes (str)'''
    
    GET_REFUND_SUMMARY = '''
        - Description: Retrieve comprehensive refund analysis
        - Key features:
            * 12-month historical refund data
            * Separate credit and debit refund metrics
            * Calculated averages and percentages
            * Total refund summary information
            * Useful for identifying abnormal refund patterns
        - Parameters:
            * merchant_number (required): Merchant identification number (format: MRCH####)
            * stat_date (required): aggregator period can be either: Day, Month or Year
        - Returns:
            * summary: Object containing overall refund metrics:
                - total_refunds: Total number of refunds (int)
                - total_volume: Total refund volume amount (str or number)
                - average_refund: Average refund amount (str or number)
            * details: Object containing specific refund breakdowns:
                - credit: Object containing credit refund metrics:
                * count: Number of credit refunds (int)
                * volume: Total volume of credit refunds (str or number)
                * percent: Percentage of credit refunds (str or number)
                - debit: Object containing debit refund metrics:
                * count: Number of debit refunds (int)
                * volume: Total volume of debit refunds (str or number)
                * percent: Percentage of debit refunds (str or number)'''
    
    GET_DECLINE_ANALYSIS = '''
        - Description: Analyze decline reasons for merchant transactions within a date range
        - Key features:
            * Groups declined transactions by reason codes
            * Provides frequency count for each decline reason
            * Includes summary statistics for total declines
            * Supports date range filtering for targeted analysis
            * Helps identify patterns in transaction rejections
        - Parameters:
            * merchant_number (required): Merchant identification number (format: MRCH####)
            * date_from (required): Start date for analysis in YYYY-MM-DD format
            * date_to (required): End date for analysis in YYYY-MM-DD format
        - Returns:
            * items: Array of decline reason objects, each containing:
                - reason: Description of the decline reason (str)
                - count: Number of declines with this reason (int)
            * summary: Object containing:
                - total_declines: Total number of declines in the period (int)
                - unique_reasons: Number of unique decline reasons (int)'''


