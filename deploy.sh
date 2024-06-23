#!/bin/bash

docker-compose -p ts-services -f docker-compose.minio-weaviate-python.ts.yaml down --remove-orphans
docker-compose -p ts-services -f docker-compose.minio-weaviate-python.ts.yaml up -d --buil