#!/bin/bash

# Install Splunk
tar xvzf /vagrant/splunkforwarder-9.1.4-a414fc70250e-Linux-x86_64.tgz -C /opt

# Create directory if it doesn't exist
if [ ! -d /opt/splunk/etc/system/local ]; then
    mkdir -p /opt/splunkforwarder/etc/system/local
fi

cat <<'EOF' >/opt/splunkforwarder/etc/system/local/outputs.conf
[default]

[indexAndForward]
index = false

[tcpout]
defaultGroup = indexer
forwardedindex.filter.disable = true
indexAndForward = false

[tcpout:indexer]
server=192.168.56.100:9997
disabled = false
EOF

# Initial Splunk setup
/opt/splunkforwarder/bin/splunk status --accept-license --answer-yes --no-prompt --seed-passwd changeme
/opt/splunkforwarder/bin/splunk enable boot-start -systemd-managed 1 -user root -group root
systemctl daemon-reload
chown root:root -R /opt/splunk

# Install splunk add-on for unix and linux
tar xvzf /vagrant/splunk-add-on-for-unix-and-linux_900.tgz -C /opt/splunkforwarder/etc/apps

# Create directory if it doesn't exist
if [ ! -d /opt/splunkforwarder/etc/apps/Splunk_TA_nix/local ]; then
    mkdir -p /opt/splunkforwarder/etc/apps/Splunk_TA_nix/local
fi

# Configure add-on inputs
cat <<'EOF' >/opt/splunkforwarder/etc/apps/Splunk_TA_nix/local/inputs.conf
[script://./bin/vmstat.sh]
interval = 1
disabled = false
index = main

[script://./bin/iostat.sh]
interval = 1
disabled = false
index = main

[script://./bin/ps.sh]
interval = 1
disabled = false
index = main

[script://./bin/top.sh]
interval = 1
disabled = false
index = main

[script://./bin/netstat.sh]
interval = 1
disabled = false
index = main

[script://./bin/lsof.sh]
interval = 1
disabled = false
index = main

[script://./bin/df.sh]
interval = 1
disabled = false
index = main
EOF

# Enable & start Splunk forwarder
systemctl enable --now SplunkForwarder