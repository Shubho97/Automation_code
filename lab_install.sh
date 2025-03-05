#!/bin/bash

echo "Srcipt for scratch install of CB* labs"
echo

echo "NOTE: BEFORE EXECUTING THE SCRIPT CHECK THE PWD IN DEPLOYMENT_TEMPLATE"
echo "----------------------------------------------------------------------"

echo
# Disk Space Check to execute the install procedure
DIRECTORY="/home/insteng/"

echo "Checking disk space for $DIRECTORY ..."

# Available disk space percentage
AVAILABLE_PERCENT=$(df -h $DIRECTORY | awk 'NR==2 {print $5}' | sed 's/%//')

echo "Disk usage: $AVAILABLE_PERCENT%"

# Check if available disk space is less than or equal to 80%
if [ $AVAILABLE_PERCENT -ge 80 ]; then
    echo "Warning: Insufficient space! You need at least 20% free disk space."
    exit 1
else
    echo "Disk space is sufficient. Proceeding with LAb Installation operations..."
fi
echo

#Directory and file_name for cbam and openstack pwd
pwd_dir_path="/home/insteng/install/configuration"
file_name="deployment_parameters.yaml"

#Exporting the details
myenv="target_environment_name"
MYENV="$(grep "^target_environment_name:" "$pwd_dir_path/$file_name" | awk '{print $2}' | tr -d '"')"
export MYENV=$MYENV

release_version="release_version"
RELEASE_VERSION="$(grep "^release_version:" "$pwd_dir_path/$file_name" | awk '{print $2}' | tr -d '"')"
export RELEASE_VERSION=$RELEASE_VERSION

export PATCH_ID=$RELEASE_VERSION

export PATCH_DIR=${INSTALL_DIR}/release/${PATCH_ID}

#Fetching CBAMPW from deployment_parameter.yaml
cbam_pwd="cbam_admin_pw"
CBAMPW="$(grep "^cbam_admin_pw:" "$pwd_dir_path/$file_name" | awk '{print $2}' | tr -d '"')"

#Fetching OSPASS from deployment_parameter.yaml
openstack_pwd="openstack_password"
OSPASS="$(grep "^openstack_password:" "$pwd_dir_path/$file_name" | awk '{print $2}' | tr -d '"')"

grep -e kvnf_version: -e release_version: ${INSTALL_DIR}/configuration/deployment_parameters.yaml

printenv
echo
#changing the directory to "ansible/vnf_deployment
dir_path="/home/insteng/ansible/vnf_deployment"

# Change to the directory
cd "$dir_path" || exit
echo "Successfully changed to directory: $dir_path"

#Condition for executing the install or upgrade command
if [[ "$RELEASE_VERSION" == "21.06.7064" ]]; then
    echo "Release version is 21.06.7064, executing base load installation"

    ansible-playbook -i inventories/production ValidateConfiguration.yml -e "openstack_password=$OSPASS" -e "cbam_admin_pw=$CBAMPW"

    nohup ansible-playbook -i inventories/production install.yml -e "openstack_password=$OSPASS" -e "cbam_admin_pw=$CBAMPW" &

    tail -f nohup.out
    echo

elif [["$RELEASE_VERSION" == "PP21.06.7064.3" || "$RELEASE_VERSION" == "PP21.06.7064.4" || "$RELEASE_VERSION" == "PP21.06.7064.5" || "$RELEASE_VERSION" == "PP21.06.7064.8" || "$RELEASE_VERSION" == "PP21.06.7064.10" || "$RELEASE_VERSION" == "PP21.06.7064.11"]]; then
    echo "Release version is $RELEASE_VERSION, executing upgrade command"

    ansible-playbook -i inventories/production UpdateConfiguration.yml -e "deployment_flag=upgrade" -e "openstack_password=$OSPASS" -e "cbam_admin_pw=$CBAMPW"

    nohup ansible-playbook -i inventories/production patch-upgrade.yml -e "@${PATCH_DIR}/deployment-templates/pp_metadata/${PATCH_ID}_core.json" &

    tail -f nohup.out
    echo

else
    #Input from user for other type of PP_version
    read -p "Enter the PP version: " USER_PP_VERSION

    if [[ "$RELEASE_VERSION" == "$USER_PP_VERSION" ]]; then
        echo "Release version is $USER_PP_VERSION, executing upgrade command"

        ansible-playbook -i inventories/production UpdateConfiguration.yml -e "deployment_flag=upgrade" -e "openstack_password=$OSPASS" -e "cbam_admin_pw=$CBAMPW"

        nohup ansible-playbook -i inventories/production patch-upgrade.yml -e "@${PATCH_DIR}/deployment-templates/pp_metadata/PP21.06.7064.10._core.json" &

        tail -f nohup.out
        
    else
        echo "Error: The entered PP version ($USER_PP_VERSION) does not match the release version ($RELEASE_VERSION)."
        exit 1
    fi
fi
