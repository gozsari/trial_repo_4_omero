#!/bin/bash

# Load environment variables from .env file
source .env

# Create the backup directory if it doesn't exist
mkdir -p $OUTPUT_DIRECTORY

# Set the appropriate permissions
chown -R $DATABASE_ADMIN $OUTPUT_DIRECTORY

# Perform the database backup using pg_dump
su $DATABASE_ADMIN -c "pg_dump -Fc -f $OUTPUT_DIRECTORY/$DATABASE.$DATE.pg_dump $DATABASE


name: Install Docker
        uses: docker/setup-buildx-action@v2

      - name: Set up Docker container for PostgreSQL
        run: |
          docker run -d --name $CONTAINER_NAME -e POSTGRES_DB=$DATABASE -e POSTGRES_USER=$DATABASE_ADMIN -e POSTGRES_PASSWORD=password -p 5432:5432 postgres:latest
          sleep 20 # Wait for the container to be ready

      - name: Run backup script in Docker mode
        run:
          chmod +x scripts/database_backup.sh 
          ./scripts/database_backup.sh docker
        env:
          OUTPUT_DIRECTORY: ${{ env.OUTPUT_DIRECTORY }}
          DATABASE: ${{ env.DATABASE }}
          DATABASE_ADMIN: ${{ env.DATABASE_ADMIN }}
          CONTAINER_NAME: ${{ env.CONTAINER_NAME }}
          DATE: ${{ env.DATE }}

      - name: Clean up Docker container
        run: docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME
