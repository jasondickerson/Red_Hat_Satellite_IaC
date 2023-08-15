# Red_Hat_Satellite_IaC

Example of using ansible-core to automatically install and configure Red Hat Satellite 6 on RHEL 8.  This example uses the following collections:

- redhat.rhel_system_roles
- redhat.satellite_operations
- redhat.satellite

Once the playbooks complete, Satellite is configured to provision RHEL 7, 8 and 9 via PXE network boot.  Also, the Satellite acts as the DNS and DHCP servers for the subnet.  

While the code works, this README is a work in progress.  Full instructions will be forthcoming...  

## Lab Environment

My test Lab is libvirt on Fedora 38.  I created a subnet 192.168.100.0/24 with DHCP disabled, and NAT forwarding.  The Gateway is 192.168.100.1, and the Satellite is 192.168.100.2.  For the Red Hat Satellite installation, the DHCP pool is the 192.168.100.100 - 150.  I deployed the Red Hat Satellite and subsequent clients into the test.org domain.  I started with a Minimal install of RHEL 8.8, registered to Red Hat Subscription Management on the Internet.  My Red Hat Satellite VM is 4 CPU x 20GB RAM with a single 150GB disk.  Given Red Hat Satellite can take up quite a bit of storage, I went with the following partition layout:

- /boot      1 GB ext4
- /     139.14 GB ext4
- swap     9.9 GB

I used the Red Hat Enterprise Linux GUI installation DVD to setup the default partitions, removed /home and added the space to /.  You may wonder why I switched from xfs to ext4.  In the past my satellite filled the disk.  I found with xfs, once you grow the file system, you cannot shrink it again.  However, with ext4 you can!  Given this is a lab I use quite a bit.  I chose to keep my options open by using ext4.

## Quick How To

### Customizations

To use this code, you need to customize the variable files for your needs.  The following should be reviewed and altered as necessary:

    Red_Hat_Satellite_IaC/
    ├── content_cleanup.yml (set how many old versions of Content Views to Keep)
    ├── group_vars
    │   └── satellites
    │       ├── main.yml (set your organization)
    │       └── vault.yml (There are several variables to set according to your needs)
    ├── host_vars
    │   └── sattest.test.org.yml (Your subscription pool id for your manifest, and satellite installer options)
    ├── inventory.yml (Your satellite FQDN must be in the satellites group, adjust the host_vars filename to match as well)
    ├── secret (This file contains your secret to decrypt your ansible vault in plain text)
    └── vars ( all of these files can be used as is, to setup a Standard Operating Environment Red Hat Satellite, but may be customized)
        ├── actkeys.yml
        ├── content_views.yml
        ├── domains.yml
        ├── hostgroups.yml
        ├── lifecycles.yml
        ├── obsoletes.yml
        ├── products.yml
        ├── subnets.yml
        └── sync_plans.yml

### Running the automation

1. Customize the variable files as needed.
    - I still have a bit of work to do here to take what should be variables out of content_cleanup.yml and standardize some variables.  I started this a few years ago and need to integrate the new installation process with the configuration processes better.  
2. Run "sat_prep.bash".  The script will do the following:
    1. Disable all but the necessary repositories for the Satellite installation.
    2. Enable the Satellite EL8 module
    3. Clear the DNF/YUM cache
    4. Install the following:
        1. ansible-core
        2. RHEL System Roles
        3. redhat.satellite ansible collection
        4. redhat.satellite_operations ansible collection
    5. Perform a full system update
    6. Reboot the system
3. Run "ansible-playbook satellite_complete_installation_configuration.yml" The following actions will be performed:
    1. Install the following (Some are optional but help to maintain code):
        - satellite (rpm packages)
        - chrony
        - sos
        - bash-completion
        - tree
        - vim-enhanced
    2. Download the sat6-queue-check.bash script
        - This is a script I wrote to help find where Satellite 6 was getting "clogged" on very large satellite installations.
    3. Configure firewalld appropriately for a provisioning Red Hat Satellite.
    4. Run the Satellite Installation
    5. Create a manifest file for the Red Hat Satellite
        - Stored in /root
    6. Store the UUID of the Manifest file
        - Stored in a text file in /root
    7. Upload the manifest into Satellite
    8. Refresh the manifest
        - This can be needed for normal maintenance, so I left it in for future day 2 operations.
    9. Manage GPG keys for Repositories
    10. Set the Default Download Policy to on_demand
        - This saves a ton of disk space!
    11. Enable the required Red Hat Repositories and any custom repositories
        - Custom repositories can include EPEL or in house created repositories
        - Note: the use of EPEL on production systems is not recommended, use it at your own risk.
    12. Create a Sync Plan
    13. Create Lifecycle Environments
    14. Sync the repository content
        - With the Default Download Policy set to on_demand, this will only download repository metadata, and create repository metadata internal to Satellite.  RPM's are downloaded to Satellite as clients request them.  
    15. Create Content Views
    16. Publish Content Views and publish them to Lifecycle Environments
    17. Create Activation Keys
    18. Create Domains
    19. Create Subnets
    20. Create Hostgroups
    21. Set the Default root password for systems created by Hostgroups.  

This covers all of the installation and configuration playbooks.  After all of this, your Satellite is ready to PXE Provision BIOS based systems!  

There is one other playbook not covered here, content_cleanup.yml.  This playbook can remove old Content View versions and disable unneeded RedHat repositories (such as old Kickstart trees).

The playbooks that begin with maintain_ are the day two operational playbooks that you can use to maintain your Red Hat Satellite Configuration over time.  

Again, this is a work in progress and more information will come in due time, and some enhancements as well... I hope to add some more features.  

## Tips

### Configure vim for yaml files

This code can not only be used to initially install Red Hat Satellite, but also maintain the configuration over time.  VIM configured for yaml files comes in handy in this case.  To do so, create the following file in the home directory of the user that will be editing the ansible variable files:

~/.vimrc

    autocmd FileType yaml setlocal et ts=2 ai sw=2 sts=0
    set modeline

### How do I find the subscription pool id(s) to add to my manifest?

Use subscription-manager to search your subscriptions:

    # subscription-manager list --all --available --matches 'Red Hat Satellite Infrastructure Subscription'

You can replace the search string with the Subscription name of your choosing.  This example searches for Red Hat Satellite Subscriptions.

### Customize the initial Organization and Location

You can add your own Organization name and Location names to the installation.  To do so, add the following to the satellite_installer_options list in the satellite server host_vars file.

    - '--foreman-initial-organization "initial_organization_name"'
    - '--foreman-initial-location "initial_location_name"'
