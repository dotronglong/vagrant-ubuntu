# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.provision "shell", inline: <<-SHELL
    cp -pr /vagrant/provision.sh /usr/bin/provision
  SHELL

  config.vm.define "lamp" do |lamp|
    lamp.vm.hostname = 'lamp'
    lamp.vm.network :private_network, ip: "192.168.33.11"
    lamp.vm.provision "shell", inline: <<-SHELL
      provision setup
      provision install_nfsd
      # provision install_httpd
      provision install_mariadb
      # provision install_php
      # provision install_phpmyadmin
      # provision install_composer
      # provision install_node
      provision info "DONE!!!"
    SHELL
  end

  config.vm.define "lemp" do |lemp|
    lemp.vm.hostname = 'lemp'
    lemp.vm.network :private_network, ip: "192.168.33.22"
    lemp.vm.provision "shell", inline: <<-SHELL
      provision setup
      provision install_nfsd
      provision install_nginx
      provision install_mariadb
      provision install_fpm
      provision install_nginx_phpmyadmin
      provision install_composer
      provision install_node
      provision install_bower
      provision install_gulp
      provision info "DONE!!!"
    SHELL
  end
end
