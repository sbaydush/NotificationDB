#!/bin/bash

## This is the install script for NotificationDB. It will install mariadb, create the database, 
## create the notification table,install httpd, configure the website and make it auto start on boot.
## You will need to create an htaccess file yourself if you wish to lockdown the site.


## Install httpd, php, mariadb, SELinux utlities
echo "Installing httpd, php, mariadb and selinux utilities"
yum group install "Web Server" -y
yum install php -y
yum group install mariadb mariadb-server -y
yum install policycoreutils-python -y


## Make httpd and mariadb start on boot
echo "Making HTTPD and MariaDB start at boot"
systemctl enable httpd
systemctl enable mariadb

## Start mariadb
echo "Starting database"
systemctl start mariadb

## Copy web files to proper location
echo "Copying webfiles to /opt/notificationdb"
mkdir /opt/notificationdb
mkdir /opt/notificationdb/html
cp -r ./webfiles/* /opt/notificationdb/html

## Create database
echo "Creating database NotificationDB"
mysql -u root -e 'create database NotificationDB'

## Import notifications table into NotificationDB database
echo "Importing table into database"
mysql -u root NotificationDB < ./database/NotificationDB.sql

## Configure httpd
echo "Configuring HTTPD service"
cp ./conf/notificationdb.conf /etc/httpd/conf.d/notificationdb.conf

## Enable firewall for port 8989
echo "Opening firewall port 8989"
firewall-cmd --add-port=8989/tcp --permanent
firewall-cmd --reload

## Fix SELinux permissions
echo "Fixing SELinux permissions"
semanage port -a -t http_port_t -p tcp 8989
semanage fcontext -a -t httpd_sys_content_t "/opt/notificationdb(/.*)?"
restorecon -Rv /opt/notificationdb

## Start httpd
echo "Starting httpd service"
systemctl start httpd

IP=`hostname -I | awk '{ print $1 }'`

echo "Success, please visit http://$IP:8989/"