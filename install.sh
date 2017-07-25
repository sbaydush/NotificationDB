#!/bin/bash

## This is the install script for NotificationDB. It will install mariadb, create the database, 
## create the notification table,install httpd, configure the website and make it auto start on boot.
## You will need to create an htaccess file yourself if you wish to lockdown the site.

## halts script on error
set -e

if [[ $(cat /etc/redhat-release 2>/dev/null) =~ "7." ]]; then
	
	## Fix yum groups
	yum groups mark convert > /dev/null
	
	## Install httpd, php, mariadb, SELinux utlities
	echo "Installing httpd, php, mariadb and selinux utilities"
	yum group install "Web Server" -y  > /dev/null
	yum install php -y  > /dev/null
	yum group install mariadb -y  > /dev/null
	yum install mariadb-server -y > /dev/null
	yum install policycoreutils-python -y  > /dev/null
	yum install php-mysql -y  > /dev/null


	## Make httpd and mariadb start on boot
	echo "Making HTTPD and MariaDB start at boot"
	systemctl enable httpd  > /dev/null
	systemctl enable mariadb  > /dev/null

	## Start mariadb
	echo "Starting database"
	systemctl start mariadb  > /dev/null

	## Copy web files to proper location
	echo "Copying webfiles to /opt/notificationdb"
	mkdir /opt/notificationdb  > /dev/null
	mkdir /opt/notificationdb/html  > /dev/null
	cp -r ./webfiles/* /opt/notificationdb/html  > /dev/null

	## Create database
	echo "Creating database NotificationDB"
	mysql -u root -e 'create database NotificationDB'  > /dev/null

	## Import notifications table into NotificationDB database
	echo "Importing table into database"
	mysql -u root NotificationDB < ./database/NotificationDB.sql  > /dev/null

	## Configure httpd
	echo "Configuring HTTPD service"
	cp ./conf/notificationdb.conf /etc/httpd/conf.d/notificationdb.conf  > /dev/null

	## Enable firewall for port 8989
	echo "Opening firewall port 8989"
	firewall-cmd --add-port=8989/tcp --permanent  > /dev/null
	firewall-cmd --reload  > /dev/null

	## Fix SELinux permissions
	echo "Fixing SELinux permissions"
	semanage port -a -t http_port_t -p tcp 8989  > /dev/null
	semanage fcontext -a -t httpd_sys_content_t "/opt/notificationdb(/.*)?"  > /dev/null
	restorecon -Rv /opt/notificationdb  > /dev/null

	## Start httpd
	echo "Starting httpd service"
	systemctl start httpd  > /dev/null

	IP=`hostname -I | awk '{ print $1 }'`

	echo "Success, please visit http://$IP:8989/"
else
	echo "This install script only works on RHEL 7 or CentOS 7"
	echo "If you are using a different distribution, please install manually"
fi
