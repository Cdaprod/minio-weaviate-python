#!/bin/bash

# Stop all running containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -a -q)

# Remove all unused volumes
docker volume prune -f

# Remove all unused networks
docker network prune -f

# Optionally remove all unused images
docker image prune -f

# Bring down any running services and remove orphans
docker-compose -p ts-services -f docker-compose.minio-weaviate-python.ts.yaml down --remove-orphans

# Bring up the services with a fresh build
docker-compose -p ts-services -f docker-compose.minio-weaviate-python.ts.yaml up -d --build

echo "Waiting 5 seconds"
sleep 5

echo "Docker Processes"
docker ps

echo "Waiting 5 seconds"
sleep 5

echo "Docker Logs MinIO"
docker logs --tail 20 minio_1

echo "Waiting 5 seconds"
sleep 5

echo "Docker Logs Weaviate"
docker logs --tail 20 weaviate_1

echo "Waiting 5 seconds"
sleep 5

echo "Docker Logs Python-App"
docker logs --tail 20 python-app_1

