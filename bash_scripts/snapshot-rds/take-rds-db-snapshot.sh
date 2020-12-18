#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

  # AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:?The AWS_DEFAULT_REGION environment variable must be set}"
  # export AWS_DEFAULT_REGION

  # CONSUL_HOST=${CONSUL_HOST?Mandatory variable not set}
  # CONSUL_PORT=${CONSUL_PORT-8500}
  # SERVICE_NAME=${SERVICE_NAME:=$BUILDKITE_PIPELINE_SLUG}

  # PG_DB_HOST=${PG_DB_HOST:=$(consulate --api-host "$CONSUL_HOST" --api-port "$CONSUL_PORT" \
  #   kv get configuration/service/"$SERVICE_NAME"/env_vars/PG_DB_HOST)}

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

NOW_DATE=$(date '+%Y-%m-%d-%H-%M')
# DB_INSTANCE_ID=$( echo ${PG_DB_HOST} | cut -d'.' -f 1)
# DB_INSTANCE_ID="${PG_DB_HOST%%.*}"
# Database: jdbc:postgresql://mytools-postgres-db.xxxxxxxxxxxxx.us-east-1.rds.amazonaws.com/sudo (PostgreSQL 11.5)
DB_INSTANCE_ID="tools-postgres-db"
SERVICE_NAME="test"

echo -e "${YELLOW}+------------------------------------------------------------------------------------+
| Checking whether any snapshotting is in progress                                 |
+------------------------------------------------------------------------------------+
${NC}"

SNAPSHOT_PROGRESS="${SNAPSHOT_PROGRESS:=true}"

while [[ "${SNAPSHOT_PROGRESS}" == true ]]; do
  SNAPSHOT_STATUS=$(aws rds describe-db-snapshots --db-instance-identifier "${DB_INSTANCE_ID}" | tr -d \" | grep Status | cut -d',' -f 1 | cut -d':' -f 2)

  if [[ "${SNAPSHOT_STATUS}" == *"creating"* ]]; then
    SNAPSHOT_PROGRESS=true
  else
    SNAPSHOT_PROGRESS=false
  fi

  if [[ "${SNAPSHOT_PROGRESS}" == true ]]; then
    echo -e "${YELLOW}A Previous snapshot is happening on RDS ${DB_INSTANCE_ID}, wait till finish to continue${NC}"
    sleep 30
  else
    echo -e "${YELLOW}No snapshots running for ${DB_INSTANCE_ID}${NC}"
    echo -e "${NC}"
  fi

done

echo -e "${GREEN}+------------------------------------------------------------------------------------+
| RDS Snapshot Instance                                                              |
+------------------------------------------------------------------------------------+
${NC}"

echo "Creating snapshot of ${DB_INSTANCE_ID}"
if [[ "${SERVICE_NAME}" == *"alexandria"* ]]; then
  SNAPSHOT_ID=$(aws rds create-db-snapshot --db-snapshot-identifier "alexandria-postgres-db-$NOW_DATE" --db-instance-identifier alexandria-postgres-db --query 'DBSnapshot.[DBSnapshotIdentifier]' --output text)
else
  SNAPSHOT_ID=$(aws rds create-db-snapshot --db-snapshot-identifier "$DB_INSTANCE_ID-$NOW_DATE" --db-instance-identifier "$DB_INSTANCE_ID" --query 'DBSnapshot.[DBSnapshotIdentifier]' --output text)
fi

  echo "Waiting to finish the snapshot for ${SNAPSHOT_ID}"
  PROGRESS_CHECK=$(aws rds wait db-snapshot-completed --db-snapshot-identifier "$SNAPSHOT_ID")

  if [[ -z "${PROGRESS_CHECK}" ]]; then
    echo -e "${GREEN}Database Snapshot was created successfully from ${DB_INSTANCE_ID}${NC}"
    exit 0
  else
    echo -e "${YELLOW} Error creating snapshot for ${SNAPSHOT_ID}${NC} "
    exit 0
  fi
