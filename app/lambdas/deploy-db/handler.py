# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os
import json
import boto3
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

def get_secret(secret_name):
    """Retrieve secret from AWS Secrets Manager"""
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name='us-east-1'
    )
    
    try:
        secret_value = client.get_secret_value(SecretId=secret_name)
        return json.loads(secret_value['SecretString'])
    except Exception as e:
        raise Exception(f"Failed to get secret: {str(e)}")

def get_sql_from_s3(bucket, file_path):
    """Get SQL content from S3"""
    s3_client = boto3.client('s3')
    try:
        response = s3_client.get_object(Bucket=bucket, Key=file_path)
        return response['Body'].read().decode('utf-8')
    except Exception as e:
        raise Exception(f"Failed to read SQL file from S3: {str(e)}")

def execute_sql(conn, sql_content):
    """Execute SQL statements"""
    try:
        with conn.cursor() as cur:
            cur.execute(sql_content)
            conn.commit()
    except Exception as e:
        conn.rollback()
        raise Exception(f"Failed to execute SQL: {str(e)}")

def lambda_handler(event, context):
    # Get environment variables and event parameters
    s3_bucket = os.environ['S3_BUCKET']
    secret_name = os.environ['DB_SECRET_NAME']

    ddl_object_key = event.get("ddl_object_key", "schema/ddl.sql")
    dml_object_key = event.get("dml_object_key", "schema/dml.sql")
    
    try:
        # Get database credentials
        secret = get_secret(secret_name)
        
        # Get SQL content from S3
        ddl_sql_content = get_sql_from_s3(s3_bucket, ddl_object_key)
        dml_sql_content = get_sql_from_s3(s3_bucket, dml_object_key)
        
        # Connect to database
        conn = psycopg2.connect(
            dbname=secret['database_name'],
            user=secret['database_username'],
            password=secret['database_password'],
            host=secret['host'],
            port=secret['port'],
            sslmode='require'
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        
        # Execute SQL
        execute_sql(conn, ddl_sql_content)
        print("DDL executed successfully")

        execute_sql(conn, dml_sql_content)
        print("DML executed successfully")
        
        # Close connection
        conn.close()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully executed scripts',
                'details': {
                    'ddl_content': ddl_object_key,
                    'dml_content': dml_object_key
                }
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
