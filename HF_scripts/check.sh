#!/bin/bash

# Check if the script is being executed from 'insteng' or not
read -p "Executing from insteng yes/no: " name
if [ "yes" == $name ]; then
    # Disk Space Check only when executed from 'insteng'
    DIRECTORY="/home/insteng/"

    echo "Checking disk space for $DIRECTORY ..."

    # Available disk space percentage
    AVAILABLE_PERCENT=$(df -h $DIRECTORY | awk 'NR==2 {print $5}' | sed 's/%//')

    echo "Disk usage: $AVAILABLE_PERCENT%"

    # Check if available disk space is less than or equal to 80%
    if [ $AVAILABLE_PERCENT -ge 90 ]; then
        echo "Warning: Insufficient space! You need at least 20% free disk space."
        exit 1
    else
        echo "Disk space is sufficient. Proceeding with Docker operations..."
    fi
else
    echo "Skipping disk space check as the script is not running from 'insteng'."
fi

# Docker-Tar-Gz Script
# Number of dependent images
read -p "Number of images dependent on svc: " input

# Arrays to store service names and versions
declare -a SVC
declare -a VERSION

# Loop to get service names and versions
for ((i=1; i<=input; i++))
do
    read -p "Enter service name $i (e.g., file-transfer-plugin/file-transfer-plugin-migrate-mariadb): " svc_name
    read -p "Enter the version for $svc_name (e.g., 0.1.28-fp2106): " svc_version

    # Store in arrays
    SVC[$i]=$svc_name
    VERSION[$i]=$svc_version
done

# Download the svc image from repo and create checksum
wget https://repo.cci.nokia.net/artifactory/neo-helm-releases/charts/${SVC[1]}-${VERSION[1]}.tgz
cksum ${SVC[1]}-${VERSION[1]}.tgz > ${SVC[1]}-${VERSION[1]}.tgz_cksum

# Docker registry path
DOCKER_REGISTRY="neo-docker-releases.repo.cci.nokia.net"

#Delete if the images are already present
docker images -a | grep ${SVC[1]}
for ((i=1; i<=input; i++))
do
    svc=${SVC[$i]}
    version=${VERSION[$i]}

    docker images -a | grep $DOCKER_REGISTRY/$svc:$version
    docker rmi $DOCKER_REGISTRY/$svc:$version
done

# Loop through the arrays and pull/save the Docker images
for ((i=1; i<=input; i++))
do
    # Get service name and version from arrays
    svc=${SVC[$i]}
    version=${VERSION[$i]}

    # Create Docker image path
    docker_image="$DOCKER_REGISTRY/$svc:$version"
    tar_file="${svc}-${version}-docker.tar.gz"

    # Pull the Docker image
    echo "Pulling Docker image: $docker_image"
    docker pull $docker_image

    if [ $? -eq 0 ]; then
        # Save the Docker image to a tar.gz file
        echo "Saving Docker image to file: $tar_file"
        docker save $docker_image > $tar_file

        if [ $? -eq 0 ]; then
            echo "Successfully created $tar_file"
            # Create the cksum file and save it
            cksum $tar_file > ${tar_file}_cksum
        else
            echo "Error: Failed to save $docker_image to $tar_file"
        fi
    else
        echo "Error: Failed to pull $docker_image"
    fi
done

echo "All Docker images have been processed."

