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

echo "Waiting 10 seconds for containers to start"
sleep 10

echo "Docker Processes"
docker ps

# Find container names dynamically
minio_container=$(docker ps --filter "name=ts-services_minio" --format "{{.Names}}")
weaviate_container=$(docker ps --filter "name=ts-services_weaviate" --format "{{.Names}}")
python_app_container=$(docker ps --filter "name=ts-services_python-app" --format "{{.Names}}")

if [ -z "$minio_container" ]; then
    echo "MinIO container not found!"
else
    echo "Docker Logs MinIO"
    docker logs --tail 20 $minio_container
fi

if [ -z "$weaviate_container" ]; then
    echo "Weaviate container not found!"
else
    echo "Docker Logs Weaviate"
    docker logs --tail 20 $weaviate_container
fi

if [ -z "$python_app_container" ]; then
    echo "Python-App container not found!"
else
    echo "Docker Logs Python-App"
    docker logs --tail 20 $python_app_container
fi