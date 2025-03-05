#!/bin/bash

# If no argument is passed, use root directory "/"
DIRECTORY="/home/insteng/"

# Get disk usage information for the specified directory
echo "Checking disk space for $DIRECTORY ..."

# Get the disk space usage and format the output
DISK_USAGE=$(df -h $DIRECTORY | awk 'NR==2 {print "Filesystem: "$1, "\nTotal: "$2, "\nUsed: "$3, "\nAvailable: "$4, "\nUsage: "$5}')

# Print the result
echo -e "$DISK_USAGE"

AVAILABLE_PERCENT=$(df -h $DIRECTORY)

if [ $AVAILABLE_PERCENT -ge 85 ]; then
    echo "Warning: Disk usage is above 85%. You need at least 20% free disk space!"
else
    echo "Disk space is sufficient."
fi

# Optionally, you can add a warning if space is low (less than 10% available)
#AVAILABLE_PERCENT=$(df -h $DIRECTORY | awk 'NR==2 {print $5}' | sed 's/%//')

#if [ $AVAILABLE_PERCENT -ge 90 ]; then
#    echo "Warning: Disk space is critically low!"
#elif [ $AVAILABLE_PERCENT -ge 75 ]; then
#    echo "Warning: Disk space is getting low!"
#else
#    echo "Disk space is sufficient."
#fi
