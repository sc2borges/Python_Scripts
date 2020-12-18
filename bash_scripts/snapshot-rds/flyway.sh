#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

CONSUL_HOST=${CONSUL_HOST?Mandatory variable not set}
CONSUL_PORT=${CONSUL_PORT-8500}

# Allow command override in the event other flyway commands want to be used e.g., baseline
FLYWAY_COMMAND=${FLYWAY_COMMAND_OVERRIDE-migrate}
FLYWAY_DOCKER_IMAGE_VERSION="6.0.4"
FLYWAY_MIGRATION_PATH=${FLYWAY_MIGRATION_PATH:=./migration/sql/}
# Due to changes in flyway 5+, the default table was made to be flyway_schema_history.
# Many of our databases were created with the <5.x default of schema_version
# To avoid table migration, we allow override for those legacy implementations
FLYWAY_TABLE=${FLYWAY_SCHEMA_TABLE-flyway_schema_history}
SERVICE_NAME=${SERVICE_NAME:=$BUILDKITE_PIPELINE_SLUG}

# As of 04/10/19 we have a split in the usage of PG_ and DATABASE_. The module (in terraform-modules), now enforces DATABASE_ vars.
# Rather than go through each legacy repository, change consul values and change service code, this lets the script work with either var.
# There is a migration path to consolidated DBs which will remove the need for this duplication
PG_DB_USER=${PG_DB_USER:=$(consulate --api-host "$CONSUL_HOST" --api-port "$CONSUL_PORT" \
  kv get configuration/service/"$SERVICE_NAME"/env_vars/PG_DB_USER)}
PG_DB_PASSWORD=${PG_DB_PASSWORD:=$(consulate --api-host "$CONSUL_HOST" --api-port "$CONSUL_PORT" \
  kv get configuration/service/"$SERVICE_NAME"/env_vars/PG_DB_PASSWORD)}
PG_DB_HOST=${PG_DB_HOST:=$(consulate --api-host "$CONSUL_HOST" --api-port "$CONSUL_PORT" \
  kv get configuration/service/"$SERVICE_NAME"/env_vars/PG_DB_HOST)}
PG_DB_NAME=${PG_DB_NAME:=$(consulate --api-host "$CONSUL_HOST" --api-port "$CONSUL_PORT" \
  kv get configuration/service/"$SERVICE_NAME"/env_vars/PG_DB_NAME)}

# Ask Consul for the database user
if [ "${PG_DB_USER}" == "None" ]; then
  PG_DB_USER=$(consulate --api-host "$CONSUL_HOST" --api-port "$CONSUL_PORT" \
    kv get configuration/service/"$SERVICE_NAME"/env_vars/DATABASE_USERNAME)

  # Due to the way consulate operates, after the first shell execution, this will _always_ be the
  # string representation of the None type from python.
  if [ "${PG_DB_USER}" == "None" ]; then
    echo "ERROR!!! Cannot read database user from Consul: $CONSUL_HOST:$CONSUL_PORT"
    exit 1
  fi
fi

# Ask Consul for the database password
if [ "${PG_DB_PASSWORD}" == "None" ]; then
  PG_DB_PASSWORD=$(consulate --api-host "$CONSUL_HOST" --api-port "$CONSUL_PORT" \
    kv get configuration/service/"$SERVICE_NAME"/env_vars/DATABASE_PASSWORD)

  # Due to the way consulate operates, after the first shell execution, this will _always_ be the
  # string representation of the None type from python.
  if [ "${PG_DB_PASSWORD}" == "None" ]; then
    echo "ERROR!!! Cannot read database password from Consul: $CONSUL_HOST:$CONSUL_PORT"
    exit 1
  fi
fi

# Ask Consul for the database host
if [ "${PG_DB_HOST}" == "None" ]; then
  PG_DB_HOST=$(consulate --api-host "$CONSUL_HOST" --api-port "$CONSUL_PORT" \
    kv get configuration/service/"$SERVICE_NAME"/env_vars/DATABASE_HOST)

  # Due to the way consulate operates, after the first shell execution, this will _always_ be the
  # string representation of the None type from python.
  if [ "${PG_DB_HOST}" == "None" ]; then
    echo "ERROR!!! Cannot read database connection string from Consul: $CONSUL_HOST:$CONSUL_PORT"
    exit 1
  fi
fi

# Ask Consul for the database name
if [ "${PG_DB_NAME}" == "None" ]; then
  PG_DB_NAME=$(consulate --api-host "$CONSUL_HOST" --api-port "$CONSUL_PORT" \
    kv get configuration/service/"$SERVICE_NAME"/env_vars/DATABASE_NAME)

  # Due to the way consulate operates, after the first shell execution, this will _always_ be the
  # string representation of the None type from python.
  if [ "${PG_DB_NAME}" == "None" ]; then
    echo "ERROR!!! Cannot read database name from Consul: $CONSUL_HOST:$CONSUL_PORT"
    exit 1
  fi
fi

docker run --rm -v "${PWD}:/flyway/sql" -w "/flyway/sql" \
  --network "${DOCKER_BUILD_NETWORK:=bridge}" \
  flyway/flyway:"${FLYWAY_DOCKER_IMAGE_VERSION}" \
  -user="${PG_DB_USER}" \
  -password="${PG_DB_PASSWORD}" \
  -initSql="set statement_timeout=0;" \
  -url="jdbc:postgresql://${PG_DB_HOST}/${PG_DB_NAME}" \
  -locations="filesystem:${FLYWAY_MIGRATION_PATH}" \
  -table="${FLYWAY_TABLE}" \
  info
