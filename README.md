# Splunk Heavy Forwarders High Availability Setup with Vagrant

This repo details the steps and configurations used to set up a high availability (HA) cluster for Splunk Heavy Forwarders using Corosync, Pacemaker, and related tools. The setup involves two Splunk Heavy Forwarders configured in an HA cluster to ensure continuity and load balancing of data processing.
For easy demonstration purposes, the setup uses Vagrant to create and configure virtual machines to set up a local Splunk environment. The environment includes one Splunk indexer, two Splunk heavy forwarders, and one Splunk universal forwarder.

## Prerequisites

Before you can use these configurations, you need to have the following:

- VirtualBox: Virtual machine management. [Install & Download VirtualBox](https://www.virtualbox.org/wiki/Downloads).
- Vagrant: Tool for building and managing virtual machine environments. [Install Vagrant](https://developer.hashicorp.com/vagrant/install).


## Setup Overview

### Virtual Machines

1. splindexer:

    - Purpose: Acts as the Splunk indexer.
    - IP: 192.168.56.41
    - RAM: 4096 MB
    - CPUs: 2

2. splunkhf1

    - Purpose: Acts as a Splunk heavy forwarder.
    - IP: 192.168.56.42
    - RAM: 2048 MB
    - CPUs: 2

3. splunkhf1

    - Purpose: Acts as a Splunk heavy forwarder.
    - IP: 192.168.56.43
    - RAM: 2048 MB
    - CPUs: 2

4. splunkuf

    - Purpose: Acts as a Splunk universal forwarder.
    - IP: 192.168.56.44
    - RAM: 2048 MB
    - CPUs: 2

### Scripts

1. splunk_indexer.sh:

    - Installs Splunk on the indexer VM
    - Configures Splunk to start at boot.
    - Sets up a listening port for receiving data from forwarders.

2. splunk_hf.sh

    - Installs Splunk on heavy forwarders VM.
    - Configures Splunk to start at boot.
    - Configures forwarding to the indexer.
    - Sets up a listening port for receiving data from forwarder.


3. splunk_uf.sh

    - Installs Splunk Universal Forwarder.
    - Configures forwarding to the virtual IP that will be setup on heavy forwarders.
    - Installs and configures the Splunk Add-on for Unix and Linux to collect various system metrics.
    - Sets up the forwarder to start at boot.

## Installation and Usage

**1. Clone the Repository:**

```bash
git clone https://github.com/mzandinia/Splunk-HF-HA.git
cd Splunk-HF-HA
```

**2. Get Splunk Enterprise and Splunk universal forwarder:**

```bash
wget -O splunk-9.1.4-a414fc70250e-Linux-x86_64.tgz https://download.splunk.com/products/splunk/releases/9.1.4/linux/splunk-9.1.4-a414fc70250e-Linux-x86_64.tgz
wget -O splunkforwarder-9.1.4-a414fc70250e-Linux-x86_64.tgz https://download.splunk.com/products/universalforwarder/releases/9.1.4/linux/splunkforwarder-9.1.4-a414fc70250e-Linux-x86_64.tgz
```

**3. Start VM via Vagrant:**

- Navigate to the directory containing the Vagrantfile.


- Run `vagrant up` to start and provision the virtual machines. This will automatically set up the Splunk environment based on the configurations defined in the Vagrantfile and the provisioning scripts.


**4. High Availability Configuration on Splunk HF**

The HA setup uses Corosync for cluster membership and messaging, Pacemaker as a cluster resource manager, and PCS (Pacemaker/Corosync Configuration System) for cluster configuration. This configuration ensures that if one Heavy Forwarder fails, the other can take over its responsibilities without data loss or significant downtime.

#### Detailed Steps

1- Install Necessary Packages on Both Nodes:

Each Heavy Forwarder requires several packages to manage the cluster and synchronize the state between nodes.

```bash
sudo apt-get update
sudo apt-get install -y corosync pacemaker pcs
sudo systemctl enable --now chrony
sudo systemctl enable --now pcsd
sudo passwd hacluster  # Set password for hacluster user
```

2- Configure Hosts File:

Update /etc/hosts on both nodes to ensure each machine can resolve the other by hostname.

For splunkhf1:

```bash
sudo vim /etc/hosts
192.168.56.42 splunkhf1
192.168.56.43 splunkhf2
```

For splunkhf2:

```bash
sudo vim /etc/hosts
192.168.56.43 splunkhf2
192.168.56.42 splunkhf1
```

3- Configure Corosync on **splunkhf1**:

Edit /etc/corosync/corosync.conf with the following configurations, which setup the cluster communication:

```bash
sudo vim /etc/corosync/corosync.conf
```


```bash
  totem {
    version: 2
    cluster_name: splunk_cluster
    transport: udpu
    interface {
        ringnumber: 0
        bindnetaddr: 192.168.56.0
        mcastport: 5405
    }
}

nodelist {
    node {
        ring0_addr: splunkhf1
        name: splunkhf1
        nodeid: 1
    }
    node {
        ring0_addr: splunkhf2
        name: splunkhf2
        nodeid: 2
    }
}

quorum {
    provider: corosync_votequorum
}

logging {
    to_syslog: yes
}
```

4- Generate Corosync authentication key on **splunkhf1**:

```bash
sudo corosync-keygen
```

5- Copy the Corosync authentication key to splunkhf2:

```bash
sudo scp -r /etc/corosync/* root@splunkhf2:/etc/corosync/
```

6- Enable and Start Corosync and Pacemaker **on both splunkhf1 and splunkhf2**:

```bash
sudo systemctl enable --now corosync pacemaker
```

7- Configure the Cluster Using PCS: Authenticate and setup the cluster on **splunkhf1**.

```bash
pcs host auth splunkhf1 splunkhf2
pcs cluster setup splunk_cluster splunkhf1 splunkhf2 --force
pcs cluster enable --all
pcs cluster start --all
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
```

8- Create Cluster Resources:

- IP Resource: A virtual IP (VIP) that clients can connect to. This IP will float between splunkhf1 and splunkhf2 depending on which node is active.
- Splunk Service: Controls the Splunk daemon ensuring it is running on the active node.

```bash
pcs resource create splunk_vip ocf:heartbeat:IPaddr2 ip=192.168.56.100 cidr_netmask=24 op monitor interval=30s op stop timeout=300s --group splunk_group
pcs resource create splunk_service systemd:Splunkd op monitor interval=60s op stop timeout=600s --group splunk_group
pcs constraint colocation add splunk_service with splunk_vip INFINITY
pcs constraint order splunk_vip then splunk_service
pcs constraint location splunk_service prefers splunkhf1=50
```

9- Verify Cluster Status:

```bash
pcs status
```

## Explanation of Configuration

- **Corosync** provides the communication layer for the HA cluster, managing membership and messaging to maintain cluster integrity.
- **Pacemaker** acts as the cluster resource manager, which allocates resources (in this case, the Splunk service and the virtual IP) to nodes and manages failover between them.
- **PCS** is used for configuring and managing the Corosync and Pacemaker based cluster.
- **Virtual IP (VIP)** ensures that client applications can connect to the cluster without needing to know which node is currently active, providing a seamless failover mechanism.
- **Splunk Service** is managed by the cluster to ensure that it is always running on one node at a time, according to the defined constraints and priorities.


This HA setup ensures that the Splunk processing capabilities are highly available, with minimal downtime in case of individual node failures. The configuration of stonith-enabled=false and no-quorum-policy=ignore is typically used in environments where more sophisticated fencing mechanisms are not available or during initial testing phases. For a production environment, it's recommended to configure proper STONITH devices to ensure data integrity and proper cluster behavior under split-brain scenarios.