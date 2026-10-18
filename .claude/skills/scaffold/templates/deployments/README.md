# __PROJECT_NAME__ deployment

```bash
# from the repo root
docker compose -f deployments/docker-compose.yml up --build
```

- Backend: http://localhost:8000 (docs at `/docs`)
- Postgres: localhost:5433 (settings come from `.env`: `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`)

The `Backend Docker CI/CD` workflow pushes the image to Docker Hub on every push to `main` that
touches `src/api/**`. It needs the repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`.
