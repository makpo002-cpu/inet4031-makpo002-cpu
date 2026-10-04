# Week 4, Docker Compose with PostgreSQL

## What this does
Runs the incident tracker and a PostgreSQL database as a two-service Compose stack, with data persisted in a named volume.

## Requirements
- Docker Compose
- A `.env` file in `week-4/` (copy `.env.example` and fill in real values)

## Run it
```bash
docker compose up -d --build
```

## Verify
```bash
docker compose ps
```

Or visit http://localhost:8080 in a browser.

## Stop it
```bash
docker compose down
```

Add `-v` only if you want to delete the database volume along with the containers.
