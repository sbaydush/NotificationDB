#!/bin/bash

## This is the install script for NotificationDB. It will install mariadb, create the database, 
## create the notification table,install httpd, configure the website and make it auto start on boot.
## You will need to create an htaccess file yourself if you wish to lockdown the site.

## halts script on error
set -e

if [[ $(cat /etc/lsb-release 2>/dev/null) =~ "Ubuntu" ]]; then
	
	## Fix yum groups
	#yum groups mark convert > /dev/null 2>&1
	
	## Install httpd, php, mariadb, SELinux utlities
	echo "Installing httpd, php and mariadb"
	apt-get install apache2 -y  > /dev/null
	apt-get install php -y  > /dev/null
	apt-get install mariadb-server -y > /dev/null
	apt-get install php-mysql -y  > /dev/null
	apt-get install libapache2-mod-php7.0 -y > /dev/null


	## Make httpd and mariadb start on boot
	echo "Making HTTPD and MariaDB start at boot"
	systemctl enable apache2 > /dev/null 2>&1
	systemctl enable mysql  > /dev/null 2>&1

	## Start mariadb
	echo "Starting database"
	systemctl start mysql  > /dev/null

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

	## Creating Database user
	echo "Creating database user"
	mysql -u root -e "CREATE USER 'ndb'@'localhost' IDENTIFIED BY 'password123';"
	mysql -u root -e "GRANT ALL PRIVILEGES ON NotificationDB.notifications TO 'ndb'@'localhost';"
	mysql -u root -e "FLUSH PRIVILEGES;"


	## Enable firewall for port 8989
	echo "Opening firewall port 8989"
	ufw allow 8989/tcp  > /dev/null

	## htaccess lockdown of site
	printf "Do you want to secure the website and api url with htaccess? (yes/no)"
	read secure

	while [[ "$secure" != "yes" && "$secure" != "no" ]]
	do
		echo you have entered an invalid response. Please try again
		printf "Do you want to secure the website and api url with htaccess? (yes/no)"
		read secure
	done
	
	if [ "$secure" = "yes" ]
	then
		echo "Locking down url with htaccess"
		while [ "$htuser" == "" ]
		do
			printf "Enter the username you wish to have access to the site with: "
			read htuser
		done
		
		while [ "$htpass" == "" ]
		do
			printf "Enter the password for $htuser: "
			read htpass
		done
		
		htpasswd -bc /opt/notificationdb/.htpasswd "$htuser" "$htpass"
	else
		echo "Skipping htaccess lockdown"
	fi
	
	
	## Configure httpd
	echo "Configuring HTTPD service"
	if [ "$secure" = "yes" ]
	then
		cp ./conf/notificationdb_secure.conf /etc/apache2/sites-available/notificationdb.conf > /dev/null
	else
		cp ./conf/notificationdb.conf /etc/apache2/sites-available/notificationdb.conf  > /dev/null
	fi
	a2ensite /etc/apache2/sites-available/notificationdb.conf
	
	
	
	## Start httpd
	echo "Starting httpd service"
	systemctl start httpd  > /dev/null

	IP=`hostname -I | awk '{ print $1 }'`

	echo "Success, please visit http://$IP:8989/"
else
	echo "This install script only works on Ubuntu"
	echo "If you are using a different distribution, please install manually"
fi
