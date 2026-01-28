FROM python:3.11-slim

WORKDIR /app

# Install system dependencies (needed for YARA or other compilation)
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Waiting for database to be ready..."\n\
for i in {1..30}; do\n\
  if pg_isready -h db -U aquadetection -d aquadetection_db > /dev/null 2>&1; then\n\
    echo "Database is ready!"\n\
    break\n\
  fi\n\
  echo "Database is unavailable - sleeping ($i/30)"\n\
  sleep 2\n\
done\n\
echo "Initializing database..."\n\
python /app/init_db.py || echo "Database already initialized"\n\
echo "Starting application..."\n\
exec uvicorn main:app --host 0.0.0.0 --port 8000 --reload' > /app/start.sh && chmod +x /app/start.sh

# Command to run
CMD ["/app/start.sh"]

