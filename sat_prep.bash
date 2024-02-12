#!/bin/bash

# Configure Satellite 6.14 repositories
subscription-manager repos --disable "*"

subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms \
  --enable=rhel-8-for-x86_64-appstream-rpms \
  --enable=satellite-6.14-for-rhel-8-x86_64-rpms \
  --enable=satellite-maintenance-6.14-for-rhel-8-x86_64-rpms

dnf -y module enable satellite:el8

# Clear dnf cache
dnf clean all
rm -rf /var/cache/yum/*

# Install Ansible
dnf -y install ansible-core rhel-system-roles ansible-collection-redhat-satellite ansible-collection-redhat-satellite_operations

# Update OS
dnf -y update

# Check if reboot is needed before proceeding
dnf needs-restarting --reboothint
