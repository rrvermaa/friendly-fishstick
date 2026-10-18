FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY src/api/core_service/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY src/api/core_service ./src/api/core_service

WORKDIR /app/src/api/core_service

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
