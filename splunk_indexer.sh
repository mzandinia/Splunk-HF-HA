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

# Create and write to inputs.conf
cat <<'EOF' >/opt/splunk/etc/system/local/inputs.conf
[default]

[splunktcp://9997]
disabled = false
EOF

# Initial Splunk setup
splunk status --accept-license --answer-yes --no-prompt --seed-passwd changeme
splunk enable boot-start -systemd-managed 1 -user root -group root
systemctl daemon-reload
chown root:root -R /opt/splunk
systemctl enable --now Splunkd