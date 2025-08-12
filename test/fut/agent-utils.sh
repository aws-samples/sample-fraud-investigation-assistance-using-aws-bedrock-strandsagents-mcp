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

# Function to test a single agent call
test_single_agent_call() {
    local question=$1
    local agent_id=$2
    local agent_alias=$3
    local region=$4
    local temp_response_file="${dir}/tmp/agent-response.json"

    python3.13 "${dir}/call_bedrock_agent.py" "$question" \
        --agent-id "$agent_id" \
        --agent-alias "$agent_alias" \
        --region "$region" \
        --output-file "$temp_response_file"
        
    # Read the response from the temporary file
    response=$(cat "$temp_response_file" | jq -r '.completion')

    # Clean up the temporary file
    rm "$temp_response_file"

    # Remove quotes from response
    response="${response%\"}"
    response="${response#\"}"
    echo "$response"
}

# Function to run all tests
run_agent_test_cases() {
    local dir=$1
    local test_case_file=$2
    local agent_id=$3
    local agent_alias=$4
    local region=$5

    echo "========================================="
    echo -e "${YELLOW}Testing Agent${NC}"

    # Read and process test cases
    test_cases=$(cat "$dir/$test_case_file" | jq -c '.tests[]')

    while IFS= read -r test_case; do
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        
        question=$(echo $test_case | jq -r '.question')
        expected_phrases=$(echo $test_case | jq -r '.expected_phrases[]')
        echo "-----------------------------------------"
        echo -e "${BOLD}Test Case $TOTAL_TESTS:${NC}"
        echo "Question: $question"
        echo -n "Expected phrases: "
        echo $test_case | jq -r '.expected_phrases[]' | paste -sd "," -
        
        response=$(test_single_agent_call "$question" "$agent_id" "$agent_alias" "$region")
        accuracy=$(get_accuracy "$response" "$expected_phrases")
        
        if [ $accuracy -eq 100 ]; then
            echo -e "${GREEN}✓ Test Passed ($accuracy% match)${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}✗ Test Failed ($accuracy% match)${NC}"
            echo "Response: $response"
            FAILED_TESTS+=("Test $TOTAL_TESTS")
        fi
    done < <(echo "$test_cases")
}

get_accuracy() {
    local response=$1
    local expected_phrases=$2
    local found=0
    local total=0
    for phrase in $expected_phrases; do
        ((total++))
        if echo "$response" | grep -qi "$phrase"; then
            ((found++))
        fi
    done

    local accuracy=$((found * 100 / total))
    echo "$accuracy"
}

# Function to print test summary
print_test_summary() {
    echo "========================================="
    echo -e "${YELLOW}Test Summary${NC}"
    echo -e "Total Tests Run: $TOTAL_TESTS"
    echo -e "Tests Passed:    ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Tests Failed:    ${RED}$((TOTAL_TESTS - PASSED_TESTS))${NC}"
    echo -e "Success Rate:    $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    echo "========================================="
}
