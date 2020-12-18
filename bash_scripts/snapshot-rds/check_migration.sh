#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# FLYAWAY 7 and above

# AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:?The AWS_DEFAULT_REGION environment variable must be set}"
# export AWS_DEFAULT_REGION
# CONSUL_HOST="${CONSUL_HOST:?Mandatory CONSUL_HOST variable not set}"
# CONSUL_PORT="${CONSUL_PORT-8500}"

FLYWAY_MIGRATION_PATH=${FLYWAY_MIGRATION_PATH:=./migration/sql/}

echo -e "${GREEN}Run flyway check${NC}"

JSON_OUTPUT=$( bash .buildkite/scripts/flyway.sh | jq '.migrations | map(. | select(.state=="Pending"))' )
PARSED_JSON=$( echo " ${JSON_OUTPUT} " | jq -r '.[] | {file: .filepath}|to_entries[]|(.value)' | awk -F / '{print $7}')

echo -e "Searching for new Migrations"

if [[ -n "${PARSED_JSON}" ]]; then
  CHECK_MIGRATIONS=true
else
  CHECK_MIGRATIONS=false
fi

if [[ "${CHECK_MIGRATIONS}" == true ]]; then
  for i in ${PARSED_JSON}; do
    if grep -ilw --include="*.sql" -e "DROP" "${FLYWAY_MIGRATION_PATH}${i}"; then

      echo -e "${GREEN}Found DROP in this Migration - Starting Snapshoting${NC}"
      bash .buildkite/scripts/take-rds-db-snapshot.sh
      exit 0
    else
      echo -e "${YELLOW}No DROP present at the current ${i} Migration file${NC}"
      echo -e "${YELLOW}Skipping Snapshot${NC}"
    fi

  done
else
  echo -e "${YELLOW}There's no Pending tasks to execute Migration${NC}"
  echo -e "${YELLOW}Skipping Snapshot${NC}"
  exit 0
fi
