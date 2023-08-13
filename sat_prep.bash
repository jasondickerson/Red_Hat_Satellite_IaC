#!/bin/bash

cd /root

# Configure Satellite 6.13 repositories
subscription-manager repos --disable "*"

subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms \
--enable=rhel-8-for-x86_64-appstream-rpms \
--enable=satellite-6.13-for-rhel-8-x86_64-rpms \
--enable=satellite-maintenance-6.13-for-rhel-8-x86_64-rpms

dnf -y module enable satellite:el8

# clear dnf cache
dnf clean all
rm -rf /var/cache/yum/*

# install Ansible
dnf -y install ansible-core rhel-system-roles ansible-collection-redhat-satellite ansible-collection-redhat-satellite_operations

# Update OS
dnf -y update

systemctl reboot
