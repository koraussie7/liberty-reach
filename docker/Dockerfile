FROM python:3.12-slim as base

# Rust ??? ??? (?? ?? ? ??)
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     curl build-essential pkg-config libssl-dev libclang-dev cmake \
#     && rm -rf /var/lib/apt/lists/

WORKDIR /app

# Python ??? ?? ?? (?? ??)
COPY server.py requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

# ?? ?? ??
COPY . .

EXPOSE 8000

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
