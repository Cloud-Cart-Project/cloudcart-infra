# ðŸ—ï¸ FleetOps Infrastructure

This directory contains the Docker Compose orchestration and database initialization scripts required to run the full FleetOps microservices platform locally.

## ðŸ—‚ï¸ Directory Structure

```
fleetops-infra/
â”œâ”€â”€ docker-compose.yml       # Defines all services, networks, and volumes
â”œâ”€â”€ database/
â”‚   â”œâ”€â”€ init-multiple-dbs.sh # Script to create 4 isolated Postgres databases
â”‚   â””â”€â”€ seed.sql             # SQL script to populate the product catalog
â”œâ”€â”€ .env.example             # Template for environment variables
â””â”€â”€ .env                     # (You create this) Local environment variables
```

## ðŸš€ How to Run

1.  **Configure Environment:**
    Copy `.env.example` to `.env` and configure your variables (at a minimum, set a strong `JWT_SECRET`).
    ```bash
    cp .env.example .env
    ```

2.  **Start the Cluster:**
    Run Docker Compose to build and start all containers in detached mode.
    ```bash
    docker compose up --build -d
    ```

3.  **Database Seeding:**
    The database is seeded automatically the first time the PostgreSQL container starts. (If you ever need to reset and re-seed, run `docker compose down -v` to wipe the volumes, then start again).

## ðŸ‘‘ Creating the Admin Account

The automatic seed script does **not** create an admin user because passwords must be securely hashed by the API. To create your admin account, run these two commands from your terminal once the app is running:

**1. Register a new user via the API:**
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"cloudadmin","email":"admin@fleetops.com","password":"Admin@123"}'
```

**2. Promote the user to the ADMIN role directly in the database:**
```bash
docker exec fleetops-postgres psql -U postgres -d auth_db -c "UPDATE users SET role='ADMIN' WHERE username='cloudadmin';"
```

You can now log into the web interface using `cloudadmin` / `Admin@123` to access the Admin Dashboard!

## ðŸ³ Services Overview

| Service | Container Name | Port (Internal) | Host Port | Depends On |
| :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL** | `fleetops-postgres` | 5432 | 5432 | - |
| **Redis** | `fleetops-redis` | 6379 | 6379 | - |
| **Auth** | `fleetops-auth-service` | 8080 | - | postgres |
| **Product** | `fleetops-vehicle-service` | 8080 | - | postgres, redis |
| **Cart** | `fleetops-maintenance-service` | 8080 | - | postgres |
| **Order** | `fleetops-request-service` | 8080 | - | postgres, product, cart |
| **Frontend** | `fleetops-frontend` | 80 | 8080 | auth, product, cart, order |

Only the Frontend NGINX server is exposed to your host machine on port `8080`. All microservice-to-microservice communication happens internally on the `fleetops-network` Docker bridge network.

## âš¡ Caching (Redis)

Redis `7-alpine` is used as a read-through cache for the `vehicle-service`.

*   **What is cached:** `GET /products`, `GET /products/{id}`, and category/search lists.
*   **TTL:** 5 minutes. Entries expire automatically.
*   **Cache Invalidation:** Any admin mutation (create, update, delete, stock change) immediately evicts the affected cache entries, so the Admin Dashboard always reflects current data.
*   **Graceful Fallback:** If Redis is unreachable at startup, the product service automatically falls back to serving all requests directly from PostgreSQL. **Redis being down will never crash the API.**
*   **What is NOT cached:** Orders, cart mutations, stock validation during checkout, and auth flows â€” these always read live from the database.


