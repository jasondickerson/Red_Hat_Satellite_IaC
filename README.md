# Red_Hat_Satellite_IaC

Example of using ansible-core to automatically install and configure Red Hat Satellite 6 on RHEL 8.  This example uses the following collections:

- redhat.rhel_system_roles
- redhat.satellite_operations
- redhat.satellite

Once the playbooks complete, Satellite is configured to provision RHEL 7, 8 and 9 via PXE network boot.  Also, the Satellite acts as the DNS and DHCP servers for the subnet.  

## Lab Environment

My test Lab is libvirt on Fedora 39.  I created a subnet 192.168.100.0/24 with DHCP disabled, and NAT forwarding.  The Gateway is 192.168.100.1, the Satellite is 192.168.100.2, and the Capsule is 192.168.100.3.  For the Red Hat Satellite installation, the DHCP pool is the 192.168.100.100 - 150.  I deployed the Red Hat Satellite, Capsule, and subsequent clients into the test.org domain.  I started with a Minimal install of RHEL 8.9, and registered the Satellite to Red Hat Subscription Management on the Internet.  My Satellite VM is 4 CPU x 20GB RAM with a single 150GB disk.  Given Red Hat Satellite can take up quite a bit of storage, I went with the following partition layout:

    /boot           1 GB  ext4
    /boot/efi     600 MB  vfat
    /          138.56 GB  ext4
    swap          9.9 GB  swap

My Capsule VM is 4 CPU x 12GB RAM with a single 150GB disk.  I used the same partition layout as the Satellite.  

I used the Red Hat Enterprise Linux GUI installation DVD to setup the default partitions, removed /home and added the space to /.  You may wonder why I switched from xfs to ext4.  In the past my satellite filled the disk.  I found with xfs, once you grow the file system, you cannot shrink it again.  However, with ext4 you can!  Given this is a lab I use quite a bit.  I chose to keep my options open by using ext4.

## Quick How To

### File Manifest

    Red_Hat_Satellite_IaC
    ├── ansible.cfg
    ├── capsule_cert_gen.yml
    ├── capsule_prep.bash
    ├── capsule_prep.yml
    ├── capsule_sync.yml
    ├── cleanup_content.yml
    ├── collections
    │   └── requirements.yml
    ├── install_capsule_packages.yml
    ├── install_capsule.yml
    ├── install_satellite_packages.yml
    ├── install_satellite.yml
    ├── inventory
    │   ├── group_vars
    │   │   ├── all
    │   │   │   └── main.yml
    │   │   ├── capsules
    │   │   │   └── main.yml
    │   │   └── satellites
    │   │       ├── content_views.yml
    │   │       ├── obsolete_repositories.yml
    │   │       ├── satellite_activation_keys.yml
    │   │       ├── satellite_lifecycle_environments.yml
    │   │       └── satellite_products.yml
    │   ├── host_vars
    │   │   ├── captest.test.org
    │   │   │   ├── content.yml
    │   │   │   ├── firewall_rules.yml
    │   │   │   ├── install_options.yml
    │   │   │   └── satellite.yml
    │   │   └── sattest.test.org
    │   │       ├── firewall_rules.yml
    │   │       ├── install_options.yml
    │   │       ├── main.yml
    │   │       ├── manifest.yml
    │   │       ├── satellite_capsules.yml
    │   │       ├── satellite_domains.yml
    │   │       ├── satellite_hostgroups.yml
    │   │       ├── satellite_locations.yml
    │   │       ├── satellite_settings.yml
    │   │       ├── satellite_subnets.yml
    │   │       ├── satellite_sync_plans.yml
    │   │       └── vault.yml
    │   └── inventory.yml
    ├── LICENSE
    ├── maintain_activation_keys.yml
    ├── maintain_capsule.yml
    ├── maintain_content.yml
    ├── maintain_locations.yml
    ├── maintain_manifest.yml
    ├── maintain_provisioning.yml
    ├── maintain_repositories.yml
    ├── maintain_satellite_settings.yml
    ├── maintain_sync_plans.yml
    ├── README.md
    ├── sat_prep.bash
    ├── secret
    └── site.yml

### Description of Files

#### Ansible Configuration

The 'ansible.cfg' file configures ansible to use:

    - The 'inventory' directory for the Ansible Inventory
    - The 'secret' file to decrypt and read Ansible Vault Files
    - The authentication necessary to download Red Hat Certified Ansible Collections from Red Hat Automation Hub

NOTE: *The capsule_prep.yml playbook requires the latest version of the redhat.satellite collection in order to ensure the capsule(s) are registered to the satellite correctly, using the redhat.satellite.registration_command module.  This version will not be available via rpm for some time, perhaps Red Hat Satellite 6.15 or 6.16.*

#### Collections Directory

The 'collections' directory contains a collections requirements file, 'requirements.yml', specifying the collections that must be downloaded for the playbooks to run.  

#### Ansible Inventory Directory

Within the 'inventory' directory you will find the following:

    inventory.yml:               File containing the inventory of Satellites.  
    group_vars:                  Directory containing group variable directories.
    group_vars/all:              Directory containing variable files to apply to all hosts. This is currently a placeholder.
    group_vars/capsules:         Directory containing variable files to apply to all Capsule hosts.  This is currently a placeholder.
    group_vars/satellites:       Directory container variable files to apply to all Satellite hosts.
    host_vars:                   Directory containing variable directories corresponding to specific hosts.
    host_vars/captest.test.org:  Directory containing variable files to apply to the captest.test.org host.
    host_vars/sattest.test.org:  Directory containing variable files to apply to the sattest.test.org host.

##### Group Variable Files

The following group variable files define the Content required for a Standard Operating Environment Satellite with RHEL 5 - 9 Repository Content.  RHEL 5 and 6 are commented as they are no longer supported.  

    satellites/content_views.yml
    satellites/obsolete_repositories.yml
    satellites/satellite_activation_keys.yml
    satellites/satellite_lifecycle_environments.yml
    satellites/satellite_products.yml

##### Host Variable Files

The following host variable files define configuration items specific to each Satellite.  

    firewall_rules.yml        Defines Firewalld rules for Satellite
    install_options.yml       Defines Satellite Installer Options
    main.yml                  Defines the Satellite Organization and Location
    manifest.yml              Set the subscription pools and quantities for the Satellite Manifest
    satellite_capsules.yml    Defines the list of Capsule Hosts for this Satellite
    satellite_domains.yml     Defines Domains
    satellite_hostgroups.yml  Defines Hostgroups
    satellite_locations.yml   Defines Locations
    satellite_settings.yml    Set any required Satellite Settings
    satellite_subnets.yml     Defines Subnets
    satellite_sync_plans.yml  Defines Sync Plans
    vault.yml                 Defines Satellite and Red Hat Subscription Portal Authentication information and Default Root Password for Provisioning.

NOTE: *If you wish to have multiple satellites with differing content, you may move the appropriate variable files from the 'group_vars/satellites' directory to the 'host_vars' directory for your satellite hosts.*

The following host variable files define configuration items specific to each Capsule.

    content.yml          Defines the Organizations, Locations, and Lifecycle Environments for the Capsule Host
    firewall_rules.yml   Defines Firewalld rules for Capsule
    install_options.yml  Defines Capsule Installer Options
    satellite.yml        Defines the Satellite the Capsule belongs to and the Organizationa and Location to use for Capsule content registration

### Required Variable Customizations

The playbook will not run without making the following customizations, assuming the exact lab environment is in place.  If your host name or network differ you will need to make appropriate changes.  

#### Satellite Host manifest.yml (Required)

Customize the subscription pools.  They are required to automatically create the manifest.  

To find the subscription pool id(s) to add to the subscription pools, use subscription-manager to search your subscriptions:

    # subscription-manager list --all --available --matches 'Red Hat Satellite Infrastructure Subscription'

You can replace the search string with the Subscription name of your choosing.  This example searches for Red Hat Satellite Subscriptions.

#### Satellite Host vault.yml (Required)

Customize the Red Hat Portal Username and Password variables.  They are required to automatically create the manifest.  

    vault_red_hat_portal_username
    vault_red_hat_portal_password

NOTE: *I preface all variables in the 'vault.yml' file with 'vault_'.  This enables me to see where these encrypted variables are coming from when reading the ansible variable files and playbooks.*

#### Review other host and group variable files

All other files may be customized to your particular use case.  

### Running the automation

#### Register the Satellites to Red Hat Subscription Management

Ensure your RHEL 8 server is registered to Red Hat Subscription Management and has access to a Satellite Infrastructure Subscription.  

#### Prepare the Ansible Control Node (Satellite) to run the playbook

Run "sat_prep.bash".  The script will do the following:

1. Disable all but the necessary repositories for the Satellite installation.
2. Enable the Satellite EL8 module
3. Clear the DNF/YUM cache
4. Install the following:
    - ansible-core
    - RHEL System Roles
    - redhat.satellite ansible collection
    - redhat.satellite_operations ansible collection
5. Perform a full system update
6. Report if a Reboot is required.

If necessary, reboot.

If you plan to build one or more capsules, run "capsule_prep.bash".  This will download the required Certified Ansible collection from Red Hat Automation Hub.  

For deployments with Capsules and/or multiple Satellites, create an SSH Private/Public Key pair for the root user on the Ansible Control node, and distribute the public key to the root user on the Capsules and other Satellites.  

#### Run the playbook

Run "ansible-playbook site.yml" The following actions will be performed:

1. Install the following (Some are optional but help to maintain code):
    - satellite (rpm packages)
    - chrony
    - sos
    - bash-completion
    - tree
    - vim-enhanced
1. Download the sat6-queue-check.bash script
    - This is a script I wrote to help find where Satellite 6 was getting "clogged" on very large satellite installations.
1. Configure firewalld appropriately for a provisioning Red Hat Satellite.
1. Run the Satellite Installation
1. Create a manifest file for the Red Hat Satellite
    - Stored in /root
1. Store the UUID of the Manifest file
    - Stored in a text file in /root
1. Upload the manifest into Satellite
1. Set Satellite Settings as appropriate
    - Set Default Download Policy to on_demand
        - This saves a ton of disk space!
1. Create non-default Satellite Locations
1. Refresh the manifest
    - This can be needed for normal maintenance, so I left it in for future day 2 operations.
1. Manage GPG keys for Repositories
1. Enable the required Red Hat Repositories and any custom repositories
    - Custom repositories can include EPEL or in house created repositories
    - Note: the use of EPEL on production systems is not recommended, use it at your own risk.
1. Sync the repository content
    - With the Default Download Policy set to on_demand, this will only download repository metadata, and create repository metadata internal to Satellite.  RPM's are downloaded to Satellite as clients request them.
1. Create a Sync Plan
1. Create Lifecycle Environments
1. Create Content Views
1. Publish Content Views and publish them to Lifecycle Environments
1. Create Activation Keys
1. Generate Capsule Certificate Bundles
1. Deploy Capsule Certificate Bundles to Capsules
1. Register Capsule to Satellite
1. Configure rpm repositories and AppStream Modules
1. Update Capsules OS
1. Reboot if necessary
1. Install the following packages on Capsules (Some are optional but help to maintain code):
    - chrony
    - sos
    - bash-completion
    - tree
    - vim-enhanced
1. Download the sat6-queue-check.bash script
    - This is a script I wrote to help find where Satellite 6 was getting "clogged" on very large satellite installations.
1. Configure firewalld appropriately for a provisioning Red Hat Satellite Capsule.
1. Retrieve Satellite OAuth Credential
1. Run the Capsule installation
1. Add Organizations, Locations, and Lifecycle Environments to Capsules
1. Synchronize the Capsules
1. Create Domains
1. Create Subnets
1. Create Hostgroups
1. Set the Default root password for systems created by Hostgroups.  

#### Summary

This covers all of the installation and configuration playbooks.  After all of this, your Satellite and Capsules are ready to PXE Provision BIOS based systems!  

There is one other playbook not covered here, 'content_cleanup.yml'.  This playbook can remove old Content View versions and disable unneeded RedHat repositories (such as old Kickstart trees).

The playbooks that begin with 'maintain_' are the day two operational playbooks that you can use to maintain your Red Hat Satellite Configuration over time.  

NOTE: *This is a work in progress.  I hope to add some new features such as Satellite and Capsule Upgrades in the future.*

## Tips

### Configure vim for yaml files

This code can not only be used to initially install Red Hat Satellite, but also maintain the configuration over time.  VIM configured for yaml files comes in handy in this case.  To do so, create the following file in the home directory of the user that will be editing the ansible variable files:

~/.vimrc

    " Long Option versions
    " ---------------------
    " expandtab   et
    " tabstop     ts
    " autoindent  ai
    " shiftwidth  sw
    " softtabstop sts
    " list        list
    " listchars   lcs (multispace option only supported on vim 9 or higher)
    " number      nu
    " ---------------------
    " To show line indentation, the following plugin may be used:
    " https://github.com/Yggdroot/indentLine.git

    autocmd FileType yaml setlocal et ts=2 ai sw=2 sts=0 list
    set nu
    set modeline
