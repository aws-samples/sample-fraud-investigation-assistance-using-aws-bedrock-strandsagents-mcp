<!-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. -->
<!-- SPDX-License-Identifier: MIT-0 -->

# Transaction MCP Resource

## Overview

The Transaction MCP server provides tools to query and filter transaction data (authorizations and settlements) from the fraud detection system

## Available Tools

### get_authorization_transaction_by_id(auth_transaction_id: str)

- Retrieves authorization transaction details by ID

#### Input Parameters:

- auth_transaction_id: Unique identifier for the authorization transaction

#### Returns - Output Parameters:

- id: Unique serial identifier
- merchant_number: Merchant identifier
- account_number: Masked card number (16 digits)
- amount: Transaction amount (decimal)
- currency: 3-letter currency code
- transaction_type: Type of transaction (Purchase, Pre Auth Complete, etc.)
- payment_method: Method used (EMV, Manual, Contactless Chip, etc.)
- card_expiry_date: Card expiration date (MM/YY)
- auth_code: Authorization code
- transaction_datetime: Full transaction timestamp
- approval_status: Transaction status (Approved, Declined)
- decline_reason: Reason for decline if applicable
- created_at: Record creation timestamp
- updated_at: Record last update timestamp

### get_settlement_transaction_by_id(settlement_transaction_id: str)
- Retrieves settlement transaction details by ID

#### Input Parameters:

- settlement_transaction_id: Unique identifier for the settlement transaction

#### Returns - Output Parameters:

- id: Unique serial identifier
- merchant_number: Merchant identifier
- account_number: Masked card number
- same_card: Indicator if same card as authorization
- transaction_date: Settlement date and time
- processed_amount: Settled amount
- auth_amount: Original authorization amount
- tran_id: Transaction identifier
- transaction_type: Type of transaction
- transaction_status: Current status
- card_issue_type: Credit/Debit indicator
- transaction_mode: Electronic/Manual
- payment_method: Method used
- auth_code: Linking authorization code
- auth_date: Original authorization date
- card_country: Card issuing country
- card_class: Consumer/Business/Corporate
- created_at: Record creation timestamp
- updated_at: Record last update timestamp

### get_transactions_by_merchant(merchant_number: str, transaction_type: str = "authorization",date_from:Optional[str] = None, date_to: Optional[str] = None)

- Get all transactions for a merchant with optional date filtering

#### Input Parameters:

- merchant_number: Merchant identifier (format: MRCH####)
- transaction_type: Type of transactions ("authorization" or "settlement")
- date_from: Start date (YYYY-MM-DD)
- date_to: End date (YYYY-MM-DD)

#### Returns - Output Parameters:
json
{
    "item": [
        {
            "id": 1,
            "merchant_number": "MRCH2885",
            "amount": "100.00",
            "transaction_datetime": "2025-04-01T10:30:00Z"
            // ... other transaction fields
        }
    ]
}


## get_recent_transactions(merchant_number: str, transaction_type: str = "authorization", limit: int = 5)
- Get most recent transactions for a merchant with configurable limit

#### Input Parameters:

- merchant_number: Merchant identifier (format: MRCH####)
- transaction_type: Type of transactions ("authorization" or "settlement")
- limit: Maximum number of transactions to retrieve (1-100, default: 5)

#### Returns - Output Parameters:
json
{
    "items": [
        {
            "id": 1,
            "merchant_number": "MRCH2885",
            "amount": "100.00",
            "transaction_datetime": "2025-04-01T10:30:00Z"
            // ... other transaction fields
        }
    ],
    "summary": {
        "total_returned": 5,
        "total_available": 50
    }
}


## get_decline_analysis(merchant_number: str, date_from: str, date_to: str, transaction_type: str = "authorization")
- Analyze decline reasons for merchant transactions within a date range

#### Input Parameters:

- merchant_number: Merchant identifier (format: MRCH####)
- date_from: Start date in YYYY-MM-DD format
- date_to: End date in YYYY-MM-DD format
- transaction_type: Type of transaction ("authorization" or "settlement")

#### Returns - Output Parameters:
json
{
    "items": [
        {
            "reason": "Insufficient Funds",
            "count": 12
        },
        {
            "reason": "Card Expired",
            "count": 5
        }
    ],
    "summary": {
        "total_declines": 17,
        "unique_reasons": 2
    }
}


## filter_transactions(field: str, value: str)
- Filter transactions based on specified field criteria

#### Input Parameters:

- field: Field name to filter on. Options include:
- transaction_type, payment_method, approval_status, transaction_status
- card_issue_type, transaction_mode, card_country, card_class
- amount, currency, auth_code, transaction_datetime, decline_reason
- value: Value to filter by (1-100 characters)

#### Returns - Output Parameters:
json
{
    "items": [
        {
            "id": 1,
            "merchant_number": "MRCH2885"
            // ... matching transaction fields
        }
    ],
    "count": 1
}


#### Queryable Fields

#### Authorization Fields
- id: Serial identifier
- merchant_number: Merchant identifier
- account_number: Masked card number
- amount: Transaction amount
- currency: Transaction currency
- transaction_type: Transaction type
- payment_method: Payment method used
- card_expiry_date: Card expiration
- auth_code: Authorization code
- transaction_datetime: Transaction timestamp
- approval_status: Approval status
- decline_reason: Decline reason if any

#### Settlement Fields
- id: Serial identifier
- merchant_number: Merchant identifier
- account_number: Masked card number
- same_card: Same card indicator
- transaction_date: Settlement date
- processed_amount: Settlement amount
- auth_amount: Authorization amount
- tran_id: Transaction ID
- transaction_type: Transaction type
- transaction_status: Settlement status
- card_issue_type: Card type
- transaction_mode: Transaction mode
- payment_method: Payment method
- auth_code: Authorization code
- auth_date: Authorization date
- card_country: Card country
- card_class: Card class

#### Error Responses
- All error responses follow this format:
json
{
    "error": "Error description message",
    "status_code": 404
}


#### Common status codes:
- 400: Bad request (invalid parameters)
- 404: Resource not found
- 500: Internal server error
- 503: Service unavailable