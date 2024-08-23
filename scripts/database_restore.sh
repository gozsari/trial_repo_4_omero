#!/bin/bash
# this script will restore a database from a backup file

# Example: ./database_restore.sh 2024-08-01
# Load environment variables from .env file
if [ ! -f /tmp/.env ]; then
    echo ".env file not found! Please create one with the necessary variables."
    exit 1
fi

source /tmp/.env
# Log file
LOG_FILE="$OUTPUT_DIRECTORY/backup_log.txt"



# if the date is not provided as an argument, then find the latest backup file
echo "OUTPUT_DIRECTORY: $OUTPUT_DIRECTORY"
echo "DATABASE: $DATABASE"



log() {
  echo "$DATE - $1" >> $LOG_FILE
}

handle_error() {
  log "An error occurred during the restore process. Exiting."
  exit 1
}
 
restore_normal() {
    log "Starting database restore in normal mode..."

    BACKUP_FILE=""
    if [ -z "$1" ]; then
        echo "Looking for the latest backup file..."
        BACKUP_FILE=$(ls -t $OUTPUT_DIRECTORY/$DATABASE.*.pg_dump 2>/dev/null | head -n1)
        if [ -z "$BACKUP_FILE" ]; then
            echo "No backup file found!"
        else
            echo "Found backup file: $BACKUP_FILE"
        fi
    else
        BACKUP_FILE=$OUTPUT_DIRECTORY/$DATABASE.$1.pg_dump
        if [ ! -f "$BACKUP_FILE" ]; then
            echo "Backup file $BACKUP_FILE not found!"
        else
            echo "Using specified backup file: $BACKUP_FILE"
        fi
    fi

    # Perform the database restore using pg_restore
    su $DATABASE_ADMIN -c "pg_restore -Fc -d $DATABASE $BACKUP_FILE" || handle_error

    log "Database restore in normal mode completed successfully."
}



restore_docker() {
  log "Starting restore in Docker mode..."

  if ! docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep $CONTAINER_NAME; then
    log "Container $CONTAINER_NAME is not running. Exiting."
    exit 1
  fi
  
  # Find the backup file 
  BACKUP_FILE=""
  # if date is not provided as a second argument, then find the latest backup file
    if [ -z "$2" ]; then
        echo "Looking for the latest backup file..."
        BACKUP_FILE=$(docker exec $CONTAINER_NAME ls -t /tmp/$DATABASE.*.pg_dump 2>/dev/null | head -n1)
        if [ -z "$BACKUP_FILE" ]; then
        echo "No backup file found!"
        else
        echo "Found backup file: $BACKUP_FILE"
        fi
    else
        BACKUP_FILE=/tmp/$DATABASE.$2.pg_dump
        if ! docker exec $CONTAINER_NAME test -f $BACKUP_FILE; then
        echo "Backup file $BACKUP_FILE not found!"
        else
        echo "Using specified backup file: $BACKUP_FILE"
        fi
    fi


  # Copy the backup file from the host machine to the Docker container
  docker cp $BACKUP_FILE $CONTAINER_NAME:/tmp/ || handle_error

  # Drop the existing database (optional, depending on your restore strategy)
  docker exec $CONTAINER_NAME psql -U $DATABASE_ADMIN -c "DROP DATABASE IF EXISTS $DATABASE;" || handle_error

  # Create a new empty database
  docker exec $CONTAINER_NAME psql -U $DATABASE_ADMIN -c "CREATE DATABASE $DATABASE;" || handle_error

  # Restore the database using pg_restore
  docker exec $CONTAINER_NAME pg_restore -U $DATABASE_ADMIN -d $DATABASE -Fc /tmp/$(basename $BACKUP_FILE) || handle_error

  # Clean up the backup file inside the container
  docker exec $CONTAINER_NAME rm /tmp/$(basename $BACKUP_FILE) || handle_error

  log "Restore in Docker mode completed successfully."
}


# if argument is not provided, restore in normal mode by default
if [ -z "$1" ]; then
    restore_normal
else
    restore_docker
fi