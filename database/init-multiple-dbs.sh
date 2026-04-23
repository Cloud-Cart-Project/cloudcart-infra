#!/bin/sh
set -e

echo "Creating multiple databases: auth_db, product_db, cart_db, order_db"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE auth_db;
    CREATE DATABASE product_db;
    CREATE DATABASE cart_db;
    CREATE DATABASE order_db;
EOSQL

echo "Multiple databases created successfully."
