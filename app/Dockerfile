FROM python:3.8
# Copy your application code and the script
COPY ./app /app
COPY ./entrypoint.sh /entrypoint.sh
# Install dependencies
RUN pip install -r /app/requirements.txt
# Make the script executable
RUN chmod +x /entrypoint.sh
# Set the script as the entry point
ENTRYPOINT ["/entrypoint.sh"]