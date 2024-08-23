# ! /bin/bash
# this script will restore a database from a backup file

# Example: ./database_restore.sh 2024-08-01
# Load environment variables from .env file
if [ ! -f /tmp/.env ]; then
    echo ".env file not found! Please create one with the necessary variables."
    exit 1
fi
source /tmp/.env

# if the date is not provided as an argument, then find the latest backup file
if [ -z "$1" ]; then
    BACKUP_FILE=$(ls -t $OUTPUT_DIRECTORY/$DATABASE.*.pg_dump | head -n1)
else
    BACKUP_FILE=$OUTPUT_DIRECTORY/$DATABASE.$1.pg_dump
fi

su $DATABASE_ADMIN -c "pg_restore -Fc -d $DATABASE $BACKUP_FILE" || handle_error