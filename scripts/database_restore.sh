#!/bin/bash
# this script will restore a database from a backup file

# Example: ./database_restore.sh 2024-08-01
# Load environment variables from .env file
if [ ! -f /tmp/.env ]; then
    echo ".env file not found! Please create one with the necessary variables."
    exit 1
fi

source /tmp/.env

BACKUP_FILE=""

# if the date is not provided as an argument, then find the latest backup file
echo "OUTPUT_DIRECTORY: $OUTPUT_DIRECTORY"
echo "DATABASE: $DATABASE"

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

echo "Restoring database from $BACKUP_FILE..."

su $DATABASE_ADMIN -c "pg_restore -Fc -d $DATABASE $BACKUP_FILE" || handle_error