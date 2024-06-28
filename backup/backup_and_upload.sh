#!/bin/bash

# Date and time for the filename
timestamp=$(date +'%Y%m%d_%H%M%S')

# Path to the directory where the script is located
backup_dir="$(dirname "$0")"

# Path to the log file
log_file="$backup_dir/backup_and_upload.log"

# Function to write messages to the log file
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$log_file"
}

# Create the log file if it doesn't exist
touch "$log_file"

# Log the start of the backup process
log_message "Starting backup process."

# Create a backup of the Similar_Design_Finder_Dev database
log_message "Creating backup of Similar_Design_Finder_Dev database."
docker exec -t $(docker-compose -f "$backup_dir/../docker-compose.yaml" ps -q postgres_dev) pg_dumpall -U admin > "$backup_dir/pg_cluster_backup_dev_$timestamp.sql"
if [ $? -eq 0 ]; then
    log_message "Successfully created backup of Similar_Design_Finder_Dev database."
else
    log_message "Error creating backup of Similar_Design_Finder_Dev database."
fi

# Create a backup of the Similar_Design_Finder_Prod database
log_message "Creating backup of Similar_Design_Finder_Prod database."
docker exec -t $(docker-compose -f "$backup_dir/../docker-compose.yaml" ps -q postgres_prod) pg_dumpall -U admin > "$backup_dir/pg_cluster_backup_prod_$timestamp.sql"
if [ $? -eq 0 ]; then
    log_message "Successfully created backup of Similar_Design_Finder_Prod database."
else
    log_message "Error creating backup of Similar_Design_Finder_Prod database."
fi

# Create a backup of the MinIO data
log_message "Creating backup of MinIO data."
docker run --rm --volumes-from $(docker-compose -f "$backup_dir/../docker-compose.yaml" ps -q minio) -v "$backup_dir":/backup busybox tar czvf /backup/minio_backup_$timestamp.tar.gz /data
if [ $? -eq 0 ]; then
    log_message "Successfully created backup of MinIO data."
else
    log_message "Error creating backup of MinIO data."
fi

# Upload backups to Google Drive
log_message "Uploading Similar_Design_Finder_Dev database backup to Google Drive."
rclone copy "$backup_dir/pg_cluster_backup_dev_$timestamp.sql" gdrive:
if [ $? -eq 0 ]; then
    log_message "Successfully uploaded Similar_Design_Finder_Dev database backup to Google Drive."
else
    log_message "Error uploading Similar_Design_Finder_Dev database backup to Google Drive."
fi

log_message "Uploading Similar_Design_Finder_Prod database backup to Google Drive."
rclone copy "$backup_dir/pg_cluster_backup_prod_$timestamp.sql" gdrive:
if [ $? -eq 0 ]; then
    log_message "Successfully uploaded Similar_Design_Finder_Prod database backup to Google Drive."
else
    log_message "Error uploading Similar_Design_Finder_Prod database backup to Google Drive."
fi

log_message "Uploading MinIO data backup to Google Drive."
rclone copy "$backup_dir/minio_backup_$timestamp.tar.gz" gdrive:
if [ $? -eq 0 ]; then
    log_message "Successfully uploaded MinIO data backup to Google Drive."
else
    log_message "Error uploading MinIO data backup to Google Drive."
fi

# Delete local backups after uploading
log_message "Deleting local backups."
rm "$backup_dir/pg_cluster_backup_dev_$timestamp.sql"
rm "$backup_dir/pg_cluster_backup_prod_$timestamp.sql"
rm "$backup_dir/minio_backup_$timestamp.tar.gz"

# Log the completion of the backup process
log_message "Backup process completed."

