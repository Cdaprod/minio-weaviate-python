#!/bin/bash

docker-compose -f docker-compose.minio-weaviate-python.ts.yaml down --remove-orphans
docker-compose -f docker-compose.minio-weaviate-python.ts.yaml up -d --buil