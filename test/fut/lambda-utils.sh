#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0


export PATH=$PATH:/usr/local/bin

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Initialize counters as global variables
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

check_contains() {
    local actual=$1
    local expected_contains=$2
    
    # Extract the text from the actual response
    local actual_text=$(echo "$actual" | jq -r '.response.responseBody["application/json"].body' | tr '[:upper:]' '[:lower:]')
    
    # Check each expected string
    for str in $(echo "$expected_contains" | jq -r '.content[].text_contains[]'); do
        # Convert to lowercase and remove extra whitespace
        str=$(echo "$str" | tr '[:upper:]' '[:lower:]' | xargs)
        if ! echo "$actual_text" | grep -qi "$str"; then
            echo -e "${RED}Missing expected content: $str${NC}"
            return 1
        fi
    done
    return 0
}

run_client_function_test_cases() {
    local dir=$1
    local function_name=$2
    local region=$3
    local test_case_file=$4
    # Run tests
    echo "========================================="
    echo -e "${YELLOW}Testing Lambda Function: ${function_name}${NC}"

    TEST_CASES=$(cat "$dir/$test_case_file")
    TEST_COUNT=$(echo "$TEST_CASES" | jq '.test_cases | length')
    ITERATIONS=1
    for i in $(seq 0 $(($TEST_COUNT - 1))); do
        for j in $(seq 0 $(($ITERATIONS - 1))); do
            # Extract test case components
            TEST_NAME=$(echo "$TEST_CASES" | jq -r ".test_cases[$i].name")
            TEST_CASE=$(echo "$TEST_CASES" | jq -c ".test_cases[$i].request_payload")
            EXPECTED_STATUS=$(echo "$TEST_CASES" | jq -r ".test_cases[$i].expected_status")
            
            # Check which type of response validation to use
            if echo "$TEST_CASES" | jq -e ".test_cases[$i].expected_response_contains" > /dev/null; then
                EXPECTED_RESPONSE=$(echo "$TEST_CASES" | jq -c ".test_cases[$i].expected_response_contains")
                VALIDATION_TYPE="contains"
            else
                EXPECTED_RESPONSE=$(echo "$TEST_CASES" | jq -c ".test_cases[$i].expected_response_body")
                VALIDATION_TYPE="exact"
            fi
            
            IGNORE_FIELDS=$(echo "$TEST_CASES" | jq -r ".test_cases[$i].ignore_fields // []")
            
            # Run the test
            run_client_lambda_test "$dir" "$function_name" "$region" \
                "$TEST_NAME" "$TEST_CASE" "$EXPECTED_STATUS" "$EXPECTED_RESPONSE" "$IGNORE_FIELDS" "$VALIDATION_TYPE"
        done
    done
}

run_client_lambda_test() {
    local dir=$1
    local function_name=$2
    local region=$3
    local test_name=$4
    local payload=$5
    local expected_status_code=$6
    local expected_response=$7
    local ignore_fields=$8
    local validation_type=$9
    local temp_response="${dir}/tmp/lambda-response.json"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo "----------------------------------------"
    echo -e "${BOLD}Test Case $TOTAL_TESTS: $test_name${NC}"

    # Create command for debugging
    command="aws lambda invoke --function-name ${function_name} --region ${region} --payload '${payload}' --cli-binary-format raw-in-base64-out ${temp_response}"
    
    # Invoke Lambda and save response
    response=$(aws lambda invoke \
        --function-name ${function_name} \
        --region ${region} \
        --payload "${payload}" \
        --cli-binary-format raw-in-base64-out \
        ${temp_response} \
        2>&1)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Invocation successful${NC}"
        
        actual_status_code=$(cat $temp_response | jq -r '.response.httpStatusCode')
        if [ "$actual_status_code" = "$expected_status_code" ]; then
            if [ "$validation_type" = "contains" ]; then
                if check_contains "$(<$temp_response)" "$expected_response"; then
                    echo -e "${GREEN}✓ Response contains all expected content${NC}"
                    PASSED_TESTS=$((PASSED_TESTS + 1))
                else
                    echo -e "${RED}✗ Response missing expected content${NC}"
                    echo -e "${RED}Response: $(cat $temp_response | jq -c '.response.responseBody')${NC}"
                    echo -e "$command"
                    FAILED_TESTS=$((FAILED_TESTS + 1))
                fi
            else
                actual_response_body=$(cat $temp_response | jq -c '.response.responseBody["application/json"].body')
                
                if [ "$ignore_fields" != "[]" ] && [ -n "$ignore_fields" ]; then
                    actual_response_body=$(echo "$actual_response_body" | jq --argjson ignore "$ignore_fields" 'delpaths($ignore | map([.]))')
                    expected_response=$(echo "$expected_response" | jq --argjson ignore "$ignore_fields" 'delpaths($ignore | map([.]))')
                fi

                if [ "$(echo $actual_response_body | jq -c .)" = "$(echo $expected_response | jq -c .)" ]; then
                    echo -e "${GREEN}✓ Response body matched${NC}"
                    PASSED_TESTS=$((PASSED_TESTS + 1))
                else
                    echo -e "${RED}✗ Response body mismatch${NC}"
                    echo -e "${RED}Expected: $expected_response"
                    echo -e "${RED}Got: $actual_response_body${NC}"
                    echo -e "$command"
                    FAILED_TESTS=$((FAILED_TESTS + 1))
                fi
            fi
        else
            echo -e "${RED}✗ Status code mismatch. Expected: $expected_status_code, Got: $actual_status_code${NC}"
            echo -e "${RED}Response: $(cat $temp_response | jq -c '.response.responseBody')${NC}"
            echo -e "$command"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        echo -e "${RED}✗ Invocation failed${NC}"
        echo "Error: ${response}"
        echo -e "$command"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

print_test_summary() {
    echo "========================================="
    echo -e "${YELLOW}Test Summary${NC}"
    echo -e "Total Tests Run: $TOTAL_TESTS"
    echo -e "Tests Passed:    ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Tests Failed:    ${RED}$((TOTAL_TESTS - PASSED_TESTS))${NC}"
    echo -e "Success Rate:    $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    echo "========================================="
}