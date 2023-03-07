# How to Install WordPress on OpenBSD 7.0 with Nginx
# WordPress is a free, open-source content management system (CMS) with rich tools and features to make website development easy.
# This article explains how to install WordPress on an OpenBSD 7.0 server with Nginx, MySQL, and PHP 7.4.
# Prerequisites
#
#    Deploy a new OpenBSD 7.0 Vultr server.
#
#    SSH and Login to the server
#
#    Install Nginx, MySQL, PHP on the server
#
# Deploy a Vultr OpenBSD 7 server and SSH to the server as root. Then, update the server.
#
pkg_add -u
#
# 1. Install Nginx
#
# By default, Nginx is available in the openBSD7 repository packages. Install it with the following command:
#
pkg_add nginx
#
# Enable Nginx to start at boot time.
#
rcctl enable nginx
#
# Start the Nginx web server.
#
rcctl start nginx
#
# 2. Install PHP
#
# Install PHP.
#
pkg_add php
#
# Select your preferred version based on applications you intend to run. For system-wide compatibility, install PHP 7.4 (option 2).
# 
# Ambiguous: choose package for php
#
#    0: <None>
#
#    1: php-7.3.33
#
#    2: php-7.4.26
#
#    3: php-8.0.13
#
# PHP-FPM is automatically installed with the PHP package. Next, you have to start it up and allow it to run when the server starts.
#
# Enable PHP-FPM to run at boot time.
#
rcctl enable php74_fpm
#
# Start PHP-FPM.
#
rcctl start php74_fpm 
#
# Install the necessary modules for PHP to connect to the MySQL server.
#
pkg_add php-mysqli php-pdo_mysql
#
# Output:
#
# Ambiguous: choose package for php-mysqli
#
#    0: <None>
#
#    1: php-mysqli-7.3.33
#
#    2: php-mysqli-7.4.26
#
#    3: php-mysqli-8.0.13
#
# Your choice: 2
#
# You can also install other PHP modules commonly required by most web applications.
#
pkg_add php-gd php-intl php-xmlrpc
#
# Enable PHP modules.
#
cp /etc/php-7.4.sample/* /etc/php-7.4
#
# 3. Configure Nginx for PHP-FPM
#
# Install Vim or your favorite text editor.
#
rcctl pkg_add vim
#
# Edit the main Nginx configuration file.
#
vim /etc/nginx/nginx.conf
#
# Within the server { block, add the following lines of code for Nginx to pass all PHP processing to the PHP-FPM socket.

location ~ \.php$ {

            try_files $uri =404;

            fastcgi_split_path_info ^(.+\.php)(/.+)$;

            fastcgi_pass   unix:run/php-fpm.sock;

            fastcgi_index index.php;

            fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;

            include fastcgi_params;

    }

# Save and close the file.
#
# Test the Nginx configuration.
#
nginx -t
#
# Output:
#
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
#
# nginx: configuration file /etc/nginx/nginx.conf test is successful
#
# Edit the main PHP-FPM configuration file.
#
vim /etc/php-fpm.conf
#
# Confirm that PHP-FPM connects through the socket /var/www/run/php-fpm.sock, and also runs with the user, group www.

; Unix user/group of processes

; Note: The user is mandatory. If the group is not set, the default users group will be used.

user = www

group = www

; The address on which to accept FastCGI requests.

; Valid syntaxes are:

;   'ip.add.re.ss:port'    - to listen on a TCP socket to a specific IPv4 address on

;                            a specific port;

;   '[ip:6:addr:ess]:port' - to listen on a TCP socket to a specific IPv6 address on

;                            a specific port;

;   'port'                 - to listen on a TCP socket to all addresses

;                            (IPv6 and IPv4-mapped) on a specific port;

;   '/path/to/unix/socket' - to listen on a unix socket.

; Note: This value is mandatory.

; If using a TCP port, never expose this to a public network.

listen = /var/www/run/php-fpm.sock

# 4. Install MariaDB
#
# Install the MariaDB service.
#
pkg_add mariadb-server
#
# Initialize the database server to create necessary binaries and system tables.
#
mysql_install_db
#
# Start the MySQL daemon.
#
rcctl start mysqld
#
# Secure MySQL by setting a new root password and removing insecure defaults.
#
mysql_secure_installation 
#
# You will receive multiple prompts, accept decisively to tighten your database server security.
#
# Switch to unix_socket authentication [Y/n] 
#
# Change the root password? [Y/n] 
#
# Remove anonymous users? [Y/n] 
# 
# Disallow root login remotely? [Y/n] 
#
# Remove test database and access to it? [Y/n] 
#
# Reload privilege tables now? [Y/n] 
#
# Enable MySQL to start at boot time.
#
rcctl enable mysqld
#
# 5. Test the Installation
#
# By default, Nginx uses the /var/www/htdocs directory as webroot. Create a new PHP sample file in that directory to test the web server.
#
vim /var/www/htdocs/test.php
#
# Paste the following PHP code:
#
<?php
phpinfo();
?>
#
# Enter your server's public IP address in a web browser and load the test.php file. Your output should be similar to:
#
# PHP Output
#
# Congratulations, you have successfully installed Nginx, MySQL, and PHP-FPM on your OpenBSD 7 server.
#
# Install PHP Extensions
#
# WordPress requires some extra PHP extensions to run well. Install them on your OpenBSD server.
#
pkg_add php-gd php-intl php-xmlrpc php-mysqli php-pdo_mysql
#
# Start PHP-FPM.
#
rcctl start php74_fpm
#
# Configure Nginx
#
# Enable PHP support in the main nginx.conf configuration file if not already enabled by directing all requests to PHP-FPM.
#
# vim /etc/nginx/nginx.conf
#
# Add the following lines of code within the server {.....} block.
#
location ~ \.php$ {

                try_files      $uri $uri/ =404;

                fastcgi_pass   unix:run/php-fpm.sock;

                fastcgi_index  index.php;

               fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;

                include        fastcgi_params;

            }
#
# Also, add index.php within the http{ block. Your declaration should look similar to the one below.
#
http {

        include       mime.types;

        default_type  application/octet-stream;

        index         index.html index.htm index.php;
#
# Save and close the file.
#
# Restart Nginx.
#
rcctl restart nginx
#
# Create a new WordPress database
#
# Run MySQL.
#
mysql
#
# Create the database.
#
MariaDB [(none)]>  CREATE DATABASE wordpress;
#
# Create a new database user and assign a strong password.
#
MariaDB [(none)]>   CREATE USER â€˜wpuserâ€™@â€™localhostâ€™ IDENTIFIED BY â€˜<strong password>â€™;
#
# Grant the user full rights to the WordPress database.
#
MariaDB [wordpress]> use wordpress;
#
#
#
MariaDB [wordpress]>  GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
#
# Refresh Privileges and exit the console.
#
MariaDB [wordpress]> FLUSH PRIVILEGES;
#
#
#
MariaDB [wordpress]> EXIT
#
# Install and Configure WordPress
#
# By default, Nginx is configured with the webroot directory /var/www/htdocs. This is where we should install all WordPress files.
#
# Download the latest WordPress tarball.
#
cd ~
#
wget https://wordpress.org/latest.tar.gz
#
# Extract the file.
#
tar -xvfz latest.tar.gz 
#
# Move extracted wordpress files to the webroot directory.
#
mv wordpress/* /var/www/htdocs/
#
# Grant Nginx ownership rights to the /var/www/htdocs directory.
#
chown -R www:www /var/www/htdocs/
#
# Now, launch the WordPress web installer by visiting your OpenBSD server IP.
#
# http://SERVER_IP
#
# Prepare your database information from the main web dashboard and click â€˜Letâ€™s Goâ€™.
#
# Enter the Database name created earlier, a Username and associated Password. Then, under Database Host replace localhost with 127.0.0.1 to avoid PHP connection issues.
#
# Wordpress Database Configuration
#
# Next, if you granted Nginx ownership rights to the /var/www/htdocs directory, a wp-config.php file will be automatically created to Install WordPress on your server.
#
# Run the installation and enter your Site Title, Administrator Username, Password, and Email Address to continue.
#
# Finally, log in to your new WordPress CMS to get started with building your websites on the platform.
# Secure the Server for Production
#
# First, delete the WordPress installation script to prevent potential attacks on your website.
#
rm /var/www/htdocs/wp-admin/install.php
#
# Then, ensure that your server has an active SSL certificate to avoid being blocked by most web browsers that may require strict https access.
#
# To get started, set up a free letâ€™s encrypt SSL certificate by create an acme-client configuration file.
#
# Using your favorite editor, create the file /etc/acme-client.conf.
#
vim /etc/acme-client.conf
#
# Paste the following code and replace example.com with your active domain name.
#
authority letsencrypt {

        api url "https://acme-v02.api.letsencrypt.org/directory"

        account key "/etc/acme/letsencrypt-privkey.pem"

}



authority letsencrypt-staging {

        api url "https://acme-staging-v02.api.letsencrypt.org/directory"

        account key "/etc/acme/letsencrypt-staging-privkey.pem"

}



domain example.com {

    alternative names { www.example.com }

    domain key "/etc/ssl/private/example.com.key"

    domain full chain certificate "/etc/ssl/example.com.crt"

    sign with letsencrypt

}

# Save and close the file.
#
# Now, request an SSL certificate by running the following command.
#
acme-client -v example.com
#
# Finally, restart Nginx.
#
rcctl restart nginx
