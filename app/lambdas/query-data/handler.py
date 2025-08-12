# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import boto3
import os
import json
import psycopg2
from psycopg2.extensions import AsIs
from typing import Dict

def get_db_connection():
    """
    Get database connection parameters from Secrets Manager and establish connection
    """
    secret_name = os.environ.get('DB_SECRET_NAME')
    region_name = os.environ.get('AWS_REGION')

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except Exception as e:
        print(f"Error getting secret: {str(e)}")
        raise e

    secret = json.loads(get_secret_value_response['SecretString'])
    
    # Connect to the database
    conn = psycopg2.connect(
        host=secret['host'],
        database=secret['database_name'],
        user=secret['database_username'],
        password=secret['database_password'],
        port=secret['port']
    )
    
    return conn

def lambda_handler(event, context):
    """
    Lambda handler that queries PostgreSQL database based on API path and filters
    """
    print(f"Received event: {json.dumps(event)}")
    
    try:
        path = event.get('path', '').lower()
        params = event.get('queryStringParameters', {}) or {}
        print(f"Processing request - Path: {path}, Params: {params}")
        
        # Get database connection
        conn = get_db_connection()
        cursor = conn.cursor()
            
        try:
            # Route the request to the appropriate handler based on path
            if path == "/api/merchant/details":
                return get_merchant_details(cursor, params)
            elif path == "/api/merchant/stats":
                return get_merchant_stats(cursor, params)
            elif path == "/api/merchant/filter-stats":
                return filter_merchant_stats(cursor, params)
            elif path == "/api/merchant/filter-data":
                return filter_merchant_data(cursor, params)
            elif path == "/api/merchant/search":
                return search_merchants(cursor, params)
            elif path == "/api/transaction/authorization":
                return get_transactions_by_merchant(cursor, params, "authorizations")
            elif path == "/api/transaction/settlement":
                return get_transactions_by_merchant(cursor, params, "settlements")
            elif path == "/api/transaction/filter":
                return filter_transactions(cursor, params)
            else:
                return create_response(404, {"error": f"Path not found: {path}"})
                
        finally:
            cursor.close()
            conn.close()
            
    except Exception as e:
        print(f"Error processing request: {str(e)}")
        return create_response(500, {"error": f"Internal server error: {str(e)}"})

def get_merchant_details(cursor, params: Dict) -> Dict:
    """Get merchant details by merchant number"""
    merchant_number = params.get('merchant_number')
    if not merchant_number:
        return create_response(400, {"error": "merchant_number parameter is required"})
    
    print(f"Getting details for merchant: {merchant_number}")
    
    try:
        query = "SELECT * FROM merchant_details WHERE merchant_number = %s"
        cursor.execute(query, (merchant_number,))
        result = cursor.fetchone()
        
        if result:
            columns = [desc[0].lower() for desc in cursor.description]
            merchant = dict(zip(columns, result))
            return create_response(200, {"item": merchant})
        else:
            return create_response(404, {"error": f"Merchant {merchant_number} not found"})
    
    except Exception as e:
        print(f"Database error in get_merchant_details: {str(e)}")
        return create_response(500, {"error": f"Database error: {str(e)}"})

def get_merchant_stats(cursor, params: Dict) -> Dict:
    """Get merchant statistics by merchant number and bucket date"""
    merchant_number = params.get('merchant_number')
    bucket_date = params.get('stat_date') 
    
    if not merchant_number:
        return create_response(400, {"error": "merchant_number parameter is required"})
    if not bucket_date:
        return create_response(400, {"error": "bucket_date parameter is required"})
    
    print(f"Getting stats for merchant: {merchant_number}, bucket_date: {bucket_date}")
    
    try:
        query = "SELECT * FROM merchant_stats WHERE merchant_number = %s AND bucket_date = %s"
        cursor.execute(query, (merchant_number, bucket_date))
        result = cursor.fetchone()
        
        if result:
            columns = [desc[0].lower() for desc in cursor.description]
            stats = dict(zip(columns, result))
            return create_response(200, {"item": stats})
        else:
            return create_response(404, {"error": f"Stats not found for merchant {merchant_number} on date {bucket_date}"})
    
    except Exception as e:
        print(f"Database error in get_merchant_stats: {str(e)}")
        return create_response(500, {"error": f"Database error: {str(e)}"})
    
def filter_merchant_stats(cursor, params: Dict) -> Dict:
    """Filter merchant statistics by period and metric type"""
    merchant_number = params.get('merchant_number')
    bucket_date = params.get('stat_date')
    metric_type = params.get('metric_type')
    
    if not merchant_number:
        return create_response(400, {"error": "merchant_number parameter is required"})
    
    print(f"Filtering stats for merchant: {merchant_number}, bucket_date: {bucket_date}, metric: {metric_type}")
    
    try:
        query = "SELECT * FROM merchant_stats WHERE merchant_number = %s AND bucket_date = %s"
        
        if metric_type and metric_type.lower() != 'all':
            metric_map = {
                'sales': ['credit_sales_', 'debit_sales_'],
                'refunds': ['credit_refunds_', 'debit_refunds_'],
                'disputes': ['credit_disputes_', 'debit_disputes_'],
                'reversals': ['credit_reversals_'],
                'authorizations': ['authorizations_'],
                'entry_method': ['entry_method_']
            }
            
            if metric_type not in metric_map:
                return create_response(400, {"error": f"Invalid metric type. Allowed values: {', '.join(metric_map.keys())}"})
            
            # Get column names that match the metric type
            cursor.execute("SELECT * FROM merchant_stats LIMIT 0")
            all_columns = [desc[0].lower() for desc in cursor.description]
            
            selected_columns = []
            for prefix in metric_map[metric_type]:
                selected_columns.extend([col for col in all_columns if col.startswith(prefix)])
            
            if not selected_columns:
                return create_response(400, {"error": f"No columns found for metric type: {metric_type}"})
            
            query = f"""
                SELECT merchant_number, bucket_date, {', '.join(selected_columns)}
                FROM merchant_stats 
                WHERE merchant_number = %s AND bucket_date = %s
            """
        
        cursor.execute(query, (merchant_number, bucket_date))
        result = cursor.fetchone()
        
        
        if not result:
            return create_response(404, {"error": f"Stats not found for merchant {merchant_number} with period {bucket_date}"})
            
        columns = [desc[0].lower() for desc in cursor.description]
        stats = dict(zip(columns, result))
        
        return create_response(200, {"item": stats})
    
    except Exception as e:
        print(f"Database error in filter_merchant_stats: {str(e)}")
        return create_response(500, {"error": f"Database error: {str(e)}"})

def filter_merchant_data(cursor, params: Dict) -> Dict:
    """Filter merchant data by field"""
    merchant_number = params.get('merchant_number')
    filter_str = params.get('filter') ###### CHANGE

    try:
        filter_str = filter_str.replace("'", '"')
        filter_params = json.loads(filter_str)
        field = filter_params.get('field')
    except (json.JSONDecodeError, AttributeError):
        return create_response(400, {"error": "Invalid filter format"})
    
    if not merchant_number:
        return create_response(400, {"error": "merchant_number parameter is required"})
    if not field:
        return create_response(400, {"error": "field parameter is required"})
    
    # Validate field name
    valid_fields = [
        'merchant_number', 'merchant_name', 'address_line1', 'address_line2', 
        'county', 'city', 'state', 'billing_address_line1', 'billing_address_line2',
        'billing_city', 'billing_county', 'billing_name', 'billing_phone',
        'billing_state', 'billing_zip_code', 'business_contact_name',
        'business_email', 'business_phone', 'business_name', 'business_zip_code',
        'business_address_line1', 'business_address_line2', 'business_city',
        'business_state', 'legal_contact_name', 'legal_phone_line1', 'legal_name',
        'country_code', 'merchant_category_code', 'merchant_category_description',
        'merchant_website', 'merchant_phone', 'merchant_zip_code',
        'standard_industrial_classification', 'sic_code', 'account_status',
        'signature_amount', 'signature_volume', 'terminated_indicator',
        'first_post_date', 'installation_date', 'last_cancel_date',
        'last_post_date', 'last_status_date', 'last_settlement_date',
        'business_address_change_date', 'business_phone_change_date',
        'business_email_change_date'
    ]
    
    if field.lower() not in [f.lower() for f in valid_fields]:
        return create_response(400, {"error": f"Invalid field name. Allowed fields: {', '.join(valid_fields)}"})
    
    print(f"Filtering merchant data: {merchant_number}, field: {field}")
    
    try:
        cursor.execute(
            "SELECT %s FROM merchant_details WHERE merchant_number = %s",
            (AsIs(field), merchant_number)
        )
        result = cursor.fetchone()
        
        if result:
            return create_response(200, {"item": {field.lower(): result[0]}})
        else:
            return create_response(404, {"error": f"Merchant {merchant_number} not found"})
    
    except Exception as e:
        print(f"Database error in filter_merchant_data: {str(e)}")
        return create_response(500, {"error": f"Database error: {str(e)}"})

def search_merchants(cursor, params: Dict) -> Dict:
    """Search merchants by business name, category code, and status"""
    business_name = params.get('business_name')
    category_code = params.get('category_code')
    status        = params.get('status')
    page          = int(params.get('page', 1))
    page_size     = int(params.get('page_size', 10))
    
    print(f"Searching merchants - Business name: {business_name}, Category: {category_code}, Status: {status}")
    
    try:
        query = "SELECT * FROM merchant_details WHERE 1=1"
        conditions = []
        values = []
        
        if business_name:
            conditions.append("business_name ILIKE %s")
            values.append(f'%{business_name}%')
        
        if category_code:
            conditions.append("merchant_category_code = %s")
            values.append(category_code)
        
        if status:
            conditions.append("merchant_id_status = %s")
            values.append(status)
        
        if conditions:
            query += " AND " + " AND ".join(conditions)
        
        # Add pagination
        offset = (page - 1) * page_size
        query += " LIMIT %s OFFSET %s"
        values.extend([page_size, offset])
        
        cursor.execute(query, tuple(values))
        results = cursor.fetchall()
        
        # Get total count
        count_query = "SELECT COUNT(*) FROM merchant_details WHERE 1=1"
        if conditions:
            count_query += " AND " + " AND ".join(conditions)
        cursor.execute(count_query, tuple(values[:-2]) if values else ())
        total_count = cursor.fetchone()[0]
        
        if results:
            columns = [desc[0].lower() for desc in cursor.description]
            merchants = [dict(zip(columns, row)) for row in results]
            
            return create_response(200, {
                "item": {
                    "merchants": merchants,
                    "pagination": {
                        "total": total_count,
                        "page": page,
                        "page_size": page_size,
                        "pages": (total_count + page_size - 1) // page_size
                    }
                }
            })
        else:
            return create_response(200, {
                "item": {
                    "merchants": [],
                    "pagination": {
                        "total": 0,
                        "page": page,
                        "page_size": page_size,
                        "pages": 0
                    }
                }
            })
    
    except Exception as e:
        print(f"Database error in search_merchants: {str(e)}")
        return create_response(500, {"error": f"Database error: {str(e)}"})
    
def filter_transactions(cursor, params: Dict) -> Dict:
    """Filter transactions by field and value"""
    table = params.get('table', 'authorizations')
    field = params.get('field')
    value = params.get('value')
    
    if not field or value is None:
        return create_response(400, {"error": "field and value parameters are required"})
    
    valid_tables = ['authorizations', 'settlements']
    if table not in valid_tables:
        return create_response(400, {"error": f"Invalid table name: {table}"})
    
    valid_fields = {
        'authorizations': [
            'merchant_number', 'account_number', 'amount', 'currency',
            'transaction_type', 'payment_method', 'card_expiry_date',
            'auth_code', 'transaction_datetime', 'approval_status',
            'decline_reason'
        ],
        'settlements': [
            'merchant_number', 'account_number', 'same_card',
            'transaction_date', 'processed_amount', 'auth_amount',
            'tran_id', 'transaction_type', 'transaction_status',
            'card_issue_type', 'transaction_mode', 'payment_method',
            'auth_code', 'auth_date', 'card_class'
        ]
    }
    
    if field not in valid_fields[table]:
        return create_response(400, {
            "error": f"Invalid field name for {table}. Allowed fields: {', '.join(valid_fields[table])}"
        })
    
    print(f"Filtering {table} where {field} = {value}")
    
    try:
        query = f"""
            SELECT * FROM {table} 
            WHERE {field} = %s 
            ORDER BY 
                CASE 
                    WHEN '{table}' = 'authorizations' THEN transaction_datetime 
                    ELSE transaction_date 
                END DESC 
            LIMIT 100
        """
        cursor.execute(query, (value,))
        results = cursor.fetchall()
        
        if results:
            columns = [desc[0].lower() for desc in cursor.description]
            transactions = [dict(zip(columns, row)) for row in results]
            return create_response(200, {
                "items": transactions,
                "count": len(transactions)
            })
        else:
            return create_response(404, {"error": f"No transactions found with {field}={value}"})
    
    except Exception as e:
        print(f"Database error in filter_transactions: {str(e)}")
        return create_response(500, {"error": f"Database error: {str(e)}"})

def get_transactions_by_merchant(cursor, params: Dict, table: str) -> Dict:
    """Get transactions for a merchant with optional date range"""
    merchant_number = params.get('merchant_number')
    date_from = params.get('date_from')
    date_to = params.get('date_to')
    
    if not merchant_number:
        return create_response(400, {"error": "merchant_number parameter is required"})
    
    valid_tables = ['authorizations', 'settlements']
    if table not in valid_tables:
        return create_response(400, {"error": f"Invalid table name: {table}"})
    
    print(f"Getting {table} transactions for merchant: {merchant_number}")
    
    try:
        date_field = "transaction_datetime" if table == "authorizations" else "transaction_date"
        
        query = f"SELECT * FROM {table} WHERE merchant_number = %s"
        values = [merchant_number]
        
        if date_from and date_to:
            query += f" AND {date_field} BETWEEN %s AND %s"
            values.extend([date_from, date_to])
        elif date_from:
            query += f" AND {date_field} >= %s"
            values.append(date_from)
        elif date_to:
            query += f" AND {date_field} <= %s"
            values.append(date_to)
        
        query += f" ORDER BY {date_field} DESC LIMIT 100"
        
        cursor.execute(query, tuple(values))
        results = cursor.fetchall()
        
        if results:
            columns = [desc[0].lower() for desc in cursor.description]
            transactions = [dict(zip(columns, row)) for row in results]
            return create_response(200, {"items": transactions})
        else:
            return create_response(404, {"error": f"No transactions found for merchant {merchant_number}"})
    
    except Exception as e:
        print(f"Database error in get_transactions_by_merchant: {str(e)}")
        return create_response(500, {"error": f"Database error: {str(e)}"})

def create_response(status_code: int, body: Dict) -> Dict:
    """
    Create a formatted response for API Gateway.
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body, default=str)
    }