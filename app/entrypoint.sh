#!/bin/bash

# Exit script on any error
set -e

# Function to check if Weaviate is up
wait_for_weaviate() {
    echo "Waiting for Weaviate to be available..."
    until python -c "import requests; requests.get('http://weaviate:8080/v1/.well-known/ready')" &> /dev/null
    do
        echo "Weaviate is unavailable - sleeping"
        sleep 1
    done
}

# Wait for Weaviate to become available
wait_for_weaviate

echo "Weaviate is up - executing main application script"
# Execute main.py, which is both the initializer and the main application logic
python main.py

# Decide whether to keep the container running based on an environment variable
if [ "${KEEP_CONTAINER_ALIVE}" = "true" ]; then
    echo "Keeping the container alive..."
    tail -f /dev/null
else
    echo "Main application script has completed. Exiting now."
    # exit 0 is optional, as the script ends naturally after this point
fi
