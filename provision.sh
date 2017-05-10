#!/bin/sh
MYSQL_ROOT_PASSWORD="123456"

say() { echo >&1 -e ":: $*"; }
info() { echo >&1 -e ":: \033[01;32m$*\033[00m"; }
warn() { echo >&2 -e ":: \033[00;31m$*\033[00m"; }
die() { echo >&2 -e ":: \033[00;31m$*\033[00m"; exit 1; }
null() { echo >/dev/null; }

setup() {
  # Setup Google DNS
  echo "nameserver 8.8.8.8" > /etc/resolv.conf
  echo "nameserver 8.8.4.4" >> /etc/resolv.conf

  # Install Public Key
  cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

  # Disable SELinux
  info "Set Up SELinux"
  cp -pr /vagrant/ops/etc/sysconfig/selinux /etc/selinux/config

  # Install necessary tools
  command="apt-get update && apt-get install -y wget vim git unzip"
  info $command && eval $command
}

install_nfsd() {
  info "Install NFS"
  apt-get install -y nfs-kernel-server nfs-common
}

install_nginx() {
  info "Install Nginx"
  yum install -y epel-release
  command="yum install -y nginx"
  info $command && eval $command
  cp -pr /vagrant/ops/nginx/nginx.conf /etc/nginx/nginx.conf
  cp -pr /vagrant/ops/nginx/conf.d/* /etc/nginx/conf.d/
  systemctl enable nginx
  systemctl start nginx
}

install_nginx_phpmyadmin() {
  mkdir /var/www/tools
  install_phpmyadmin
  ln -s /var/www/tools/phpmyadmin /var/www/html/phpmyadmin
}

install_httpd() {
  info "Install Apache"
  command="apt-get install -y apache2"
  info $command && eval $command

  cp -pr /vagrant/ops/apache2/sites-enabled/* /etc/apache2/sites-enabled/
}

install_mariadb() {
  info "Install MariaDB"
  sudo apt-get install software-properties-common
  sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
  sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://sgp1.mirrors.digitalocean.com/mariadb/repo/10.1/ubuntu trusty main'
  command="apt-get update && apt-get install -y mariadb-server"
  info $command && eval $command
  mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
  mysql -e "GRANT ALL PRIVILEGES ON * . * TO 'root'@'%';"
  mysql -e "FLUSH PRIVILEGES;"
}

install_php() {
  info "Install PHP"
  rpm -Uvh /vagrant/ops/rpm/epel-release-latest-7.noarch.rpm
  rpm -Uvh /vagrant/ops/rpm/webtatic-release.rpm
  command="yum install -y --skip-broken php71w-* mod_php71w"
  info $command && eval $command
  cp -pr /vagrant/ops/php/conf.d/10-php.conf /etc/httpd/conf.modules.d/10-php.conf
  cp -pr /vagrant/ops/php/php.d/* /etc/php.d/
}

install_fpm() {
  install_php
  cp -pr /vagrant/ops/php-fpm.d/* /etc/php-fpm.d/
  systemctl enable php-fpm
  systemctl start php-fpm
}

install_phpmyadmin() {
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

install_composer() {
  info "Install Composer"
  curl -SLO https://getcomposer.org/composer.phar
  chmod +x composer.phar
  mv composer.phar /usr/local/bin/composer
}

install_nvm() {
  info "Install NVM"
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
  source ~/.bashrc
}

install_node() {
  info "Install NodeJS"
  info "Use Version 6.1.0"
  nvm install 6.1.0
  nvm alias default 6.1.0
  nvm use default
}
$*
