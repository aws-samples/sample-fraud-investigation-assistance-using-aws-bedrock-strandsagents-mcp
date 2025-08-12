# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

class TransactionToolDescriptions:
    GET_AUTHORIZATION_TRANSACTION_BY_ID = '''
        - Description: Retrieves detailed authorization transaction information by transaction ID          
        - Key features:
            * Fetches complete transaction records from the authorization system
            * Provides merchant identification, transaction amounts, and payment details
            * Includes approval status and decline reasons when applicable
            * Returns timestamp information for audit and tracking
            * Supports fraud analysis with comprehensive transaction attributes
        - Parameters:
            * auth_transaction_id (required): Unique identifier for the authorization transaction
        - Returns:
            * id: Unique transaction identifier
            * merchant_number: Merchant identification code
            * account_number: Associated account number (partially masked)
            * amount: Transaction amount
            * currency: Transaction currency code
            * transaction_type: Type of transaction
            * payment_method: Method used for payment
            * card_expiry_date: Expiration date of payment card
            * auth_code: Authorization code from payment processor
            * transaction_datetime: Date and time of transaction
            * approval_status: Approval status (Approved/Declined)
            * decline_reason: Reason for decline if applicable
            * created_at: Record creation timestamp
            * updated_at: Record last update timestamp'''
    
    GET_SETTLEMENT_TRANSACTION_BY_ID = '''
        - Description: Retrieves settlement transaction information by transaction ID             
        - Key features:
            * Provides complete settlement transaction data for reconciliation
            * Shows processed amounts versus authorized amounts
            * Includes card classification and country information
            * Tracks transaction status throughout the settlement process
            * Supports investigation of settlement discrepancies             
        - Parameters:
            * settlement_transaction_id (required): Unique identifier for the settlement transaction                
        - Returns:
            * id: Unique settlement identifier (int)
            * merchant_number: Merchant identification code (str)
            * account_number: Associated account number (str, masked)
            * same_card: Indicates if same card as authorization (str)
            * transaction_date: Date of the settlement transaction (str)
            * processed_amount: Amount that was processed (str)
            * auth_amount: Original authorized amount (str)
            * tran_id: Transaction reference ID (str)
            * transaction_type: Type of settlement transaction (str)
            * transaction_status: Current status of transaction (str)
            * card_issue_type: Type of card issued (str)
            * transaction_mode: Mode of transaction processing (str)
            * payment_method: Method used for payment (str)
            * auth_code: Authorization code from processor (str)
            * auth_date: Date of original authorization (str)
            * card_country: Country of card issuance (str)
            * card_class: Classification of payment card (str)
            * created_at: Record creation timestamp (str)
            * updated_at: Record last update timestamp (str)'''
    
    GET_TRANSACTIONS_BY_MERCHANT = '''
        - Description: Retrieves complete transaction history for a merchant within specified date range
        - Key features:
            * Supports both authorization and settlement transaction types
            * Optional date range filtering for targeted analysis
            * Comprehensive transaction listing for merchant activity review
            * Ideal for pattern recognition and merchant behavior analysis
            * Helps identify unusual transaction volumes or amounts
        - Parameters:
            * merchant_number (required): Merchant identification number (format: MRCH####)
            * transaction_type (optional): Type of transaction to retrieve - "authorization" or "settlement" (default: "authorization")
            * date_from (optional): Start date in YYYY-MM-DD format
            * date_to (optional): End date in YYYY-MM-DD format
        - Returns:
            * item: Array of transaction objects containing all transaction details
            * Each transaction object includes all fields from either AuthorizationTransactionResponse or SettlementTransactionResponse depending on transaction_type'''
    
    GET_RECENT_TRANSACTIONS = '''
        - Description: Fetches the most recent transactions for a merchant, sorted by transaction datetime
        - Key features:
            * Returns transactions sorted by recency (newest first)
            * Configurable result limit (1-100 transactions)
            * Supports both authorization and settlement transaction types
            * Includes helpful summary statistics
            * Ideal for quick review of latest merchant activity
        - Parameters:
            * merchant_number (required): Merchant identification number (format: MRCH####)
            * transaction_type (optional): Type of transaction - "authorization" or "settlement" (default: "authorization")
            * limit (optional): Maximum number of transactions to retrieve (range: 1-100, default: 5)
        - Returns:
            * items: Array of recent transaction objects sorted by date (newest first)
            * summary: Object containing:
                - total_returned: Number of transactions returned (int)
                - total_available: Total number of transactions available (int)'''
    
    FILTER_TRANSACTIONS = '''
        - Description: Filters transactions based on specified criteria and field values
        - Key features:
            * Flexible field-based filtering across multiple attributes
            * Supports filtering on transaction type, payment method, status and more
            * Returns all transactions matching the specified criteria
            * Includes count of matching transactions
            * Ideal for targeted fraud investigation and pattern analysis
        - Parameters:
            * field (required): Field name to filter on - options include:
                - transaction_type, payment_method, approval_status, transaction_status,
                - card_issue_type, transaction_mode, card_country, card_class,
                - amount, currency, auth_code, transaction_datetime, decline_reason
            * value (required): Value to filter by (1-100 characters)
        - Returns:
            * items: Array of AuthorizationTransactionResponse and SettlementTransactionResponse
            * count: Total number of matching transactions (int)'''