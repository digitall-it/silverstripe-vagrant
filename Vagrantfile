# -*- mode: ruby -*-
# vi: set ft=ruby :

#v1.1

  name = "sitename"
  host = name + ".it"


Vagrant.configure("2") do |config|

  config.vm.box = "elastic/centos-7-x86_64"
  config.vm.define name

  config.vm.hostname = "dev." + host
  config.vm.network "private_network", ip: "192.168.33.16"


  config.vm.box_check_update = false

  config.vm.network "forwarded_port", guest: 8080, host: 8080

  # config.vm.network "public_network"
#  config.vm.synced_folder "./htdocs", "/var/www/html", :mount_options => ["dmode=777", "fmode=666"]
# config.vm.synced_folder "./htdocs", "/var/www/html", :nfs => { :mount_options => ["dmode=777","fmode=666"] }
  config.vm.synced_folder "./htdocs", "/var/www/html", id: "v-root", mount_options: ["rw", "tcp", "nolock", "noacl", "async", ], type: "nfs", nfs_udp: false, :nfs => { :mount_options => ["dmode=777","fmode=666"] }
#  config.vm.synced_folder "./logs", "/var/log/httpd", id: "v-logs", mount_options: ["rw", "tcp", "nolock", "noacl", "async", ], type: "nfs", nfs_udp: false, :nfs => { :mount_options => ["dmode=777","fmode=666"] }
    if Vagrant.has_plugin?("vagrant-nfs_guest")
        config.vm.synced_folder "./logs", "/var/log/httpd", type: 'nfs_guest'
    end

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "./data", "/vagrant_data" /var/www/html, /var/log/httpd
  
  config.vm.provision "shell", path: "provisioner4.3.sh", env: {"VM_HOSTNAME" => config.vm.hostname }

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
