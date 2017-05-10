#!/bin/sh
MYSQL_ROOT_PASSWORD="123456"

say() { echo >&1 -e ":: $*"; }
info() { echo >&1 -e ":: \033[01;32m$*\033[00m"; }
warn() { echo >&2 -e ":: \033[00;31m$*\033[00m"; }
die() { echo >&2 -e ":: \033[00;31m$*\033[00m"; exit 1; }
null() { echo >/dev/null; }

function setup() {
  # Setup Google DNS
  echo "nameserver 8.8.8.8" > /etc/resolv.conf
  echo "nameserver 8.8.4.4" >> /etc/resolv.conf

  # Install Public Key
  cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

  # Disable SELinux
  info "Set Up SELinux"
  cp -pr /vagrant/ops/etc/sysconfig/selinux /etc/sysconfig/selinux

  # Install necessary tools
  command="yum install -y wget curl vim git unzip"
  info $command && eval $command

  # Repos
  cp -pr /vagrant/ops/yum.repos.d/* /etc/yum.repos.d/
}

function install_nfsd() {
  info "Install NFS"
  systemctl enable rpcbind
  systemctl enable nfs-server
}

function install_nginx() {
  info "Install Nginx"
  yum install -y epel-release
  command="yum install -y nginx"
  info $command && eval $command
  cp -pr /vagrant/ops/nginx/nginx.conf /etc/nginx/nginx.conf
  cp -pr /vagrant/ops/nginx/conf.d/* /etc/nginx/conf.d/
  systemctl enable nginx
  systemctl start nginx
}

function install_nginx_phpmyadmin() {
  mkdir /var/www/tools
  install_phpmyadmin
  ln -s /var/www/tools/phpmyadmin /var/www/html/phpmyadmin
}

function install_httpd() {
  info "Install Apache"
  command="yum install -y httpd httpd-devel httpd-tools"
  info $command && eval $command

  cp -pr /vagrant/ops/httpd/conf/httd.conf /etc/httpd/conf/httpd.conf
  cp -pr /vagrant/ops/httpd/conf.d/* /etc/httpd/conf.d/
  systemctl enable httpd
  systemctl start httpd
  mkdir /var/www/tools
}

function install_mariadb() {
  info "Install MariaDB"
  yum remove -y mariadb-*
  rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
  command="yum install -y MariaDB-server MariaDB-client"
  info $command && eval $command
  systemctl enable mariadb
  systemctl start mariadb
  mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
  mysql -e "GRANT ALL PRIVILEGES ON * . * TO 'root'@'%';"
  mysql -e "FLUSH PRIVILEGES;"
}

function install_php() {
  info "Install PHP"
  rpm -Uvh /vagrant/ops/rpm/epel-release-latest-7.noarch.rpm
  rpm -Uvh /vagrant/ops/rpm/webtatic-release.rpm
  command="yum install -y --skip-broken php71w-* mod_php71w"
  info $command && eval $command
  cp -pr /vagrant/ops/php/conf.d/10-php.conf /etc/httpd/conf.modules.d/10-php.conf
  cp -pr /vagrant/ops/php/php.d/* /etc/php.d/
}

function install_fpm() {
  install_php
  cp -pr /vagrant/ops/php-fpm.d/* /etc/php-fpm.d/
  systemctl enable php-fpm
  systemctl start php-fpm
}

function install_phpmyadmin() {
  info "Install phpMyAdmin"
  curl -SLO https://files.phpmyadmin.net/phpMyAdmin/4.7.0/phpMyAdmin-4.7.0-english.zip
  unzip phpMyAdmin-4.7.0-english.zip
  rm -rf phpMyAdmin-4.7.0-english.zip
  mv phpMyAdmin-4.7.0-english phpmyadmin
  cp -pr /vagrant/ops/phpmyadmin/config.inc.php phpmyadmin/config.inc.php
  mv phpmyadmin /var/www/tools/phpmyadmin

  echo "Alias /phpmyadmin /var/www/tools/phpmyadmin" >> /etc/httpd/conf.d/alias.conf
  cp -pr /vagrant/ops/phpmyadmin/phpmyadmin.conf /etc/httpd/conf.d/phpmyadmin.conf
}

function install_composer() {
  info "Install Composer"
  curl -SLO https://getcomposer.org/composer.phar
  chmod +x composer.phar
  mv composer.phar /usr/local/bin/composer
}

function install_node() {
  info "Install NodeJS"
  curl -SLO https://nodejs.org/dist/v7.9.0/node-v7.9.0-linux-x64.tar.xz
  tar -xf node-v7.9.0-linux-x64.tar.xz
  rm -rf node-v7.9.0-linux-x64.tar.xz
  mv node-v7.9.0-linux-x64 /usr/local/share/node
  echo 'export PATH=$PATH:/usr/local/share/node/bin' >> /etc/profile
  export PATH=$PATH:/usr/local/share/node/bin
}

function install_bower() {
  export PATH=$PATH:/usr/local/share/node/bin
  info "Install Bower"
  command="npm install -g bower"
  info $command && eval $command
}

function install_gulp() {
  export PATH=$PATH:/usr/local/share/node/bin
  info "Install Gulp"
  command="npm install -g gulp"
  info $command && eval $command
}
$*
