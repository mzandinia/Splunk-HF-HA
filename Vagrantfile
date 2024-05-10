Vagrant.configure("2") do |config|
    config.vm.define "splindexer" do |splindexer|
      splindexer.vm.box = "ubuntu/jammy64"
      splindexer.vm.hostname = "splindexer"
      splindexer.vm.network "private_network", ip: "192.168.56.41"
      splindexer.vm.provision "file", source: "./splunk_indexer.sh", destination: "/tmp/splunk_indexer.sh"
      splindexer.vm.provision "shell", privileged: true, inline: "bash /tmp/splunk_indexer.sh"
      splindexer.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
        vb.cpus = "2"
      end
    end

    config.vm.define "splunkhf1" do |splunkhf1|
      splunkhf1.vm.box = "ubuntu/jammy64"
      splunkhf1.vm.hostname = "splunkhf1"
      splunkhf1.vm.network "private_network", ip: "192.168.56.42"
      splunkhf1.vm.provision "file", source: "./splunk_hf.sh", destination: "/tmp/splunk_hf.sh"
      splunkhf1.vm.provision "shell", privileged: true, inline: "bash /tmp/splunk_hf.sh"
      splunkhf1.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
        vb.cpus = "2"
      end
    end

    config.vm.define "splunkhf2" do |splunkhf2|
      splunkhf2.vm.box = "ubuntu/jammy64"
      splunkhf2.vm.hostname = "splunkhf2"
      splunkhf2.vm.network "private_network", ip: "192.168.56.43"
      splunkhf2.vm.provision "file", source: "./splunk_hf.sh", destination: "/tmp/splunk_hf.sh"
      splunkhf2.vm.provision "shell", privileged: true, inline: "bash /tmp/splunk_hf.sh"
      splunkhf2.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
        vb.cpus = "2"
      end
    end

    config.vm.define "splunkuf" do |splunkuf|
      splunkuf.vm.box = "ubuntu/jammy64"
      splunkuf.vm.hostname = "splunkuf"
      splunkuf.vm.network "private_network", ip: "192.168.56.44"
      splunkuf.vm.provision "file", source: "./splunk_uf.sh", destination: "/tmp/splunk_uf.sh"
      splunkuf.vm.provision "shell", privileged: true, inline: "bash /tmp/splunk_uf.sh"
      splunkuf.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
        vb.cpus = "2"
      end
    end

  end