#!/bin/bash

# Install Splunk
tar xvzf /vagrant/splunk-9.1.4-a414fc70250e-Linux-x86_64.tgz -C /opt

# Create symbolic link if it doesn't exist
if [ ! -L /usr/bin/splunk ]; then
    ln -s /opt/splunk/bin/splunk /usr/bin/splunk
fi

# Create directory if it doesn't exist
if [ ! -d /opt/splunk/etc/system/local ]; then
    mkdir -p /opt/splunk/etc/system/local
fi

cat <<'EOF' >/opt/splunk/etc/system/local/inputs.conf
[defult]

[splunktcp://9997]
disabled = false
EOF

cat <<'EOF' >/opt/splunk/etc/system/local/outputs.conf
[default]

[indexAndForward]
index = false

[tcpout]
defaultGroup = indexer
forwardedindex.filter.disable = true
indexAndForward = false

[tcpout:indexer]
server=192.168.56.41:9997
disabled = false
EOF

# Initial Splunk setup
splunk status --accept-license --answer-yes --no-prompt --seed-passwd changeme
splunk enable boot-start -systemd-managed 1 -user root -group root
systemctl daemon-reload
chown root:root -R /opt/splunk
systemctl enable --now Splunkd