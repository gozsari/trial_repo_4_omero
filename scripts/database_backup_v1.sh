#!/bin/bash

# Load environment variables from .env file
source .env

# Create the backup directory if it doesn't exist
mkdir -p $OUTPUT_DIRECTORY

# Set the appropriate permissions
chown -R $DATABASE_ADMIN $OUTPUT_DIRECTORY

# Perform the database backup using pg_dump
su $DATABASE_ADMIN -c "pg_dump -Fc -f $OUTPUT_DIRECTORY/$DATABASE.$DATE.pg_dump $DATABASE



