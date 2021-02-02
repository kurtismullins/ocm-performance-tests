#!/usr/bin/env bash

# Collect Environment Variables
[ -z "$OCM_TOKEN" ] && echo "Environment variable not set: OCM_TOKEN" && exit 1
[ -z "$ES_HOST" ] && echo "Environment variable not set: ES_HOST" && exit 1
[ -z "$OCM_HOST" ] && echo "Environment variable not set: OCM_HOST" && exit 1

# Ensure dependencies exist
[ ! -x "$(command -v vegeta)" ] && echo "Vegeta not found. Is it installed?" && exit 1
[ ! -x "$(command -v run_snafu)" ] && echo "Snafu not found. Is it installed?" && exit 1
[ ! -x "$(command -v uuid)" ] && echo "uuid not found. Is it installed?" && exit 1

# Configuration
rate='10/1s'
duration='60s'
export es=$ES_HOST  # required by snafu
export es_index='ocm-snafu'
test_id=$(uuid)

echo "---------------------------------------------"
echo "Beginning OCM Tests"
echo "Test ID:    ${test_id}"
echo "Throughput: ${rate}"
echo "Duration:   ${duration}"
echo "Date:       $(date)"
echo "---------------------------------------------"
echo ""

echo "-----------------------------"
echo "Test: List Subscriptions"
echo "-----------------------------"
vegeta attack -format http -rate ${rate} -output vegeta-output -duration ${duration} << EOF
GET ${OCM_HOST}/api/accounts_mgmt/v1/subscriptions
Authorization: Bearer ${OCM_TOKEN}
EOF
cat ./vegeta-output | vegeta report
cat ./vegeta-output | vegeta report --every '1s' --type 'json' --output 'vegeta-output.json'
run_snafu -t 'vegeta' -u $test_id --target_name "list_subscriptions" -r 'vegeta-output.json'

echo ""
echo "--------------------------"
echo "Test: List Organizations"
echo "--------------------------"
vegeta attack -format http -rate ${rate} -output vegeta-output -duration ${duration} << EOF
GET ${OCM_HOST}/api/accounts_mgmt/v1/organizations
Authorization: Bearer ${OCM_TOKEN}
EOF
cat ./vegeta-output | vegeta report
cat ./vegeta-output | vegeta report --every '1s' --type 'json' --output 'vegeta-output.json'
run_snafu -t 'vegeta' -u $test_id --target_name "list_organizations" -r 'vegeta-output.json'

echo ""
echo "--------------------------"
echo "Test: List Clusters"
echo "--------------------------"
vegeta attack -format http -rate ${rate} -output vegeta-output -duration ${duration} << EOF
GET ${OCM_HOST}/api/clusters_mgmt/v1/clusters
Authorization: Bearer ${OCM_TOKEN}
EOF
cat ./vegeta-output | vegeta report
cat ./vegeta-output | vegeta report --every '1s' --type 'json' --output 'vegeta-output.json'
run_snafu -t 'vegeta' -u $test_id --target_name "list_clusters" -r 'vegeta-output.json'
