#!/bin/bash

# Load environment variables from .env file
if [ ! -f /tmp/.env ]; then
    echo ".env file not found! Please create one with the necessary variables."
    exit 1
fi
source /tmp/.env

# Date format
DATE=$(date '+%Y-%m-%d')

# echo environment variables
echo "OUTPUT_DIRECTORY: $OUTPUT_DIRECTORY"
echo "DATABASE: $DATABASE"
echo "DATABASE_ADMIN: $DATABASE_ADMIN"
echo "CONTAINER_NAME: $CONTAINER_NAME"
echo "DATE: $DATE"

# Log file
LOG_FILE="$OUTPUT_DIRECTORY/backup_log.txt"

log() {
  echo "$DATE - $1" >> $LOG_FILE
}

handle_error() {
  log "Error during backup process. Exiting."
  exit 1
}

# Validate environment variables
if [ -z "$OUTPUT_DIRECTORY" ] || [ -z "$DATABASE" ] || [ -z "$DATABASE_ADMIN" ]; then
  echo "Missing environment variables. Please check .env file."
  exit 1
fi

# Function to perform backup in a normal environment
backup_normal() {
  log "Starting backup in normal mode..."

  

  # Perform the database backup using pg_dump
  su $DATABASE_ADMIN -c "pg_dump -Fc -f $OUTPUT_DIRECTORY/$DATABASE.$DATE.pg_dump $DATABASE" || handle_error

  log "Backup in normal mode completed successfully."
}

# Function to perform backup in a Docker environment
backup_docker() {
  log "Starting backup in Docker mode..."

  if ! docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep $CONTAINER_NAME; then
    log "Container $CONTAINER_NAME is not running. Exiting."
    exit 1
  fi

  # Perform the database backup using pg_dump inside the container
  docker exec $CONTAINER_NAME pg_dump -U $DATABASE_ADMIN -Fc -f /tmp/$DATABASE.$DATE.pg_dump $DATABASE || handle_error

  # Copy the backup file from the container to the host machine
  docker cp $CONTAINER_NAME:/tmp/$DATABASE.$DATE.pg_dump $OUTPUT_DIRECTORY || handle_error

  # Clean up the backup file inside the container
  docker exec $CONTAINER_NAME rm /tmp/$DATABASE.$DATE.pg_dump || handle_error

  log "Backup in Docker mode completed successfully."
}

# Create the backup directory if it doesn't exist
mkdir -p $OUTPUT_DIRECTORY

# Set the appropriate permissions
chown -R $DATABASE_ADMIN $OUTPUT_DIRECTORY


# Check if a parameter was passed to the script for Docker mode
if [ "$1" == "docker" ]; then
  backup_docker
else
  backup_normal
fi

log "Backup script completed."
