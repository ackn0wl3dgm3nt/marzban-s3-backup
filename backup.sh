#!/bin/bash

# Define variables
DIRS_FILE="dirs.txt"
ARCHIVE_NAME="backup_$(date +'%Y%m%d_%H%M%S').tar.gz"
S3_BUCKET="your-s3-bucket-name"
S3_PATH="s3://$S3_BUCKET/backups/"

# Create a temporary directory for the files to be archived
TEMP_DIR=$(mktemp -d)

# Read dirs.txt and copy files/directories to the temp directory
while IFS= read -r line; do
    # Extract the path and the copy instruction from the line
    FILE_PATH=$(echo $line | cut -d' ' -f1)
    COPY_INSTRUCTION=$(echo $line | cut -d' ' -f2-)
    
    # If the instruction is "copy entire dir", copy the directory
    if [[ $COPY_INSTRUCTION == "(copy entire dir)" ]]; then
        cp -r $FILE_PATH $TEMP_DIR/
    # If the instruction is "copy only db file", copy the file
    elif [[ $COPY_INSTRUCTION == "(copy only db file)" ]]; then
        cp $FILE_PATH $TEMP_DIR/
    fi
done < "$DIRS_FILE"

# Compress the copied files into an archive
tar -czf $ARCHIVE_NAME -C $TEMP_DIR .

# Upload the archive to S3
aws s3 cp $ARCHIVE_NAME $S3_PATH

# Clean up temporary files
rm -rf $TEMP_DIR
rm $ARCHIVE_NAME

echo "Backup complete and uploaded to $S3_PATH"
