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
duration='300s'
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

# Declare all endpoints with a given name
declare -A endpoints
endpoints['list_subscriptions']='/api/accounts_mgmt/v1/subscriptions'
endpoints['list_organizations']='/api/accounts_mgmt/v1/organizations'
endpoints['list_clusters']='/api/clusters_mgmt/v1/clusters'
endpoints['list_errors']='/api/accounts_mgmt/v1/errors'
endpoints['get_current_account']='/api/accounts_mgmt/v1/current_account'
endpoints['list_labels']='/api/accounts_mgmt/v1/labels'
endpoints['list_metrics']='/api/accounts_mgmt/v1/metrics'
endpoints['list_accounts']='/api/accounts_mgmt/v1/accounts'
endpoints['list_plans']='/api/accounts_mgmt/v1/plans'
endpoints['list_registries']='/api/accounts_mgmt/v1/registries'
endpoints['list_registry_credentials']='/api/accounts_mgmt/v1/registry_credentials'
endpoints['list_role_bindings']='/api/accounts_mgmt/v1/role_bindings'
endpoints['list_resource_quotas']='/api/accounts_mgmt/v1/resource_quota'
endpoints['list_reserved_resources']='/api/accounts_mgmt/v1/reserved_resources'
endpoints['list_skus']='/api/accounts_mgmt/v1/skus'
endpoints['list_sku_rules']='/api/accounts_mgmt/v1/sku_rules'

# Create a directory to store all test logs
mkdir -p logs

# Execute Vegeta on each Endpoint and write the results to Elasticsearch
for i in "${!endpoints[@]}"
do

target=$i
path=${array[$i]}

echo "-----------------------------"
echo "Test: $target"
echo "-----------------------------"
vegeta attack -format http -rate ${rate} -output ./logs/${test_id}_${target} -duration ${duration} <<- EOF
GET ${OCM_HOST}${path}
Authorization: Bearer ${OCM_TOKEN}
EOF
cat ./logs/${test_id}_${target} | vegeta report
cat ./logs/${test_id}_${target} | vegeta report --every '1s' --type 'json' --output "./logs/${test_id}_${target}.json"
run_snafu -t 'vegeta' -u $test_id --target_name ${target} -r "./logs/${test_id}_${target}.json"

done
