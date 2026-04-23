#!/bin/sh
set -e

echo "Creating FleetOps databases: auth_db, vehicle_db, maintenance_db, request_db"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE auth_db;
    CREATE DATABASE vehicle_db;
    CREATE DATABASE maintenance_db;
    CREATE DATABASE request_db;
EOSQL

echo "FleetOps databases created successfully."

echo "Seeding vehicle_db..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "vehicle_db" -f /docker-entrypoint-initdb.d/seed.sql
echo "Vehicle seeding completed."
