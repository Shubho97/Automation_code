#!/bin/bash

# Prompt user for the number of images
read -p "Number of images dependent on svc: " input

# Declare arrays to store service names and versions
declare -a SVC
declare -a VERSION

# Loop to get service names and versions
for ((i=1; i<=input; i++))
do
    read -p "Enter service name $i (eg. file-transfer-plugin/file-transfer-plugin-migrate-mariadb): " svc_name
    read -p "Enter the version for $svc_name (eg. 0.1.28-fp2106): " svc_version

    # Store in arrays
    SVC[$i]=$svc_name
    VERSION[$i]=$svc_version

done

#Downloading the svc image from repo
wget https://repo.cci.nokia.net/artifactory/neo-helm-releases/charts/${SVC[1]}-${VERSION[1]}.tgz

# Define Docker registry URL
DOCKER_REGISTRY="neo-docker-releases.repo.cci.nokia.net"

# Loop through the arrays and pull/save the images
for ((i=1; i<=input; i++))
do
    # Get service name and version from arrays
    svc=${SVC[$i]}
    version=${VERSION[$i]}

    # Create Docker image path and tarball file
    docker_image="$DOCKER_REGISTRY/$svc:$version"
    tar_file="${svc}-${version}-docker.tar.gz"

    # Pull the Docker image
    echo "Pulling Docker image: $docker_image"
    docker pull $docker_image

    if [ $? -eq 0 ]; then
        # Save the Docker image to a tar.gz file
        echo "Saving Docker image to file: $tar_file"
        docker save $docker_image | gzip > $tar_file

        if [ $? -eq 0 ]; then
            echo "Successfully created $tar_file"
        else
            echo "Error: Failed to save $docker_image to $tar_file"
        fi
    else
        echo "Error: Failed to pull $docker_image"
    fi
done

echo "All Docker images have been processed."

