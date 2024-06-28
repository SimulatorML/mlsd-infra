# MLSD-Infra
This repository contains the infrastructure code for the MLSD project.

## Requirements
- Two data bases: one for development and one for production
- One S3 data base in Minio


We also have backups that are made once a day in the 3AM using cronjobs and rclone sending the backups to Google Drive.
