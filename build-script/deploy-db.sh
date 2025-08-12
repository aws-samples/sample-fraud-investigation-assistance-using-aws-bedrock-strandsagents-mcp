# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

AWS_REGION=us-east-1
DB_SECRET_NAME=""
INPUT_FILE=""


# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--secret-name)
            DB_SECRET_NAME="$2"
            shift 2
            ;;
        -i|--input-file)
            INPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Error: Unknown option $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$DB_SECRET_NAME" ]]; then
    echo_error "Secret name is required (-s, --secret-name)"
    usage
fi

if [[ -z "$INPUT_FILE" ]]; then
    echo_error "input file is required (-i, --input-file)"
    usage
fi

echo "Secret name: $DB_SECRET_NAME"
echo "Input file: $INPUT_FILE"
echo 

get_db_credentials() {
    echo "Getting secret creds..."
    local secret_value
    secret_value=$(aws secretsmanager get-secret-value \
        --region "${AWS_REGION}" \
        --secret-id "${DB_SECRET_NAME}" \
        --query SecretString \
        --no-cli-pager \
        --output text) || {
            echo "Error: Failed to retrieve secret from AWS Secrets Manager"
            exit 1
        }
    echo "DB Secret values retrieved."
    
    DB_NAME=$(echo "$secret_value" | jq -r .database_name)
    DB_USER=$(echo "$secret_value" | jq -r .database_username)
    DB_PASSWORD=$(echo "$secret_value" | jq -r .database_password)
    DB_HOST=$(echo "$secret_value" | jq -r .host)
    DB_PORT=$(echo "$secret_value" | jq -r .port)

    PSQL_CONNECTION_STRING="postgres://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=require"
}

deploy_db() {
    echo "deploying $INPUT_FILE to database..."
   
    if command -v psql &> /dev/null; then
        echo "Using 'psql' command..."
        echo "connecting to server : $DB_HOST : $DB_PORT"
        ENCODED_CONNECTION_STRING=$(printf %s "$PSQL_CONNECTION_STRING" | jq -sRr @uri)
        PGHOST="$DB_HOST" PGPORT="$DB_PORT" PGUSER="$DB_USER" PGPASSWORD="$DB_PASSWORD" PGDATABASE="$DB_NAME" psql -w -f "$INPUT_FILE" \
        || {
                echo "Error: Database deployment failed"
                exit 1
            }
    else
        echo "psql not available. please install!"
    fi
    echo "Deployment of DDL completed successfully ${INPUT_FILE}"
}

get_db_credentials

deploy_db