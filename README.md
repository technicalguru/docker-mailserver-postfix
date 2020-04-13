Kubernetes-ready Mail system with Postfix, Amavis, SpamAssassin, Postfix Admin and Roundcube WebMail

Pods required:
 - MySQL 8.0:     mysql (can be replaced by mariadb)
 - PhpMyAdmin:    phpmyadmin
 - Postfix Core:  technicalguru/rs-mailserver-postfix
 - PostfixAdmin:  technicalguru/rs-mailserver-postfixadmin
 - RoundcubeMail: technicalguru/rs-mailserver-roundcube
 - Amavis       : technicalguru/rs-mailserver-amavis
 - SpamAssassin:  technicalguru/rs-mailserver-spamassassin

Configuration technicalguru/rs-mailserver-postfix:
==================================================
Environment Variables:
   PF_DB_HOST:       Service Name of database server, e.g. db-service
   PF_DB_NAME:       Database name, e.g. mail
   PF_DB_USER:       Database user, e.g. postfix
   PF_DB_PASS:       Database password, e.g. postfix
   PF_MYDOMAIN:      Domain of your mailserver, e.g. mydomain.tld
   PF_MYHOSTNAME:    HELO string of mailserver, shall match your domain's MX entry
   PF_MYORIGIN:      DNS name of your mailserver, shall match your domain's MX entry
   PF_TLS_CERT_FILE: Your server's SSL certificate
   PF_TLS_KEY_FILE:  Your server's SSL key file
   PF_TLS_CAFILE:    The CA file (can be empty)
   PF_TLS_CAPATH:    The CA path, usually at /etc/ssl/certs

Configuration technicalguru/rs-mailserver-postfixadmin:
=======================================================
Environment Variables:
   PF_DB_HOST:       Service Name of database server, e.g. db-service (must match postfix container config)
   PF_DB_NAME:       Database name, e.g. mail (must match postfix container config)
   PF_DB_USER:       Database user, e.g. postfix (must match postfix container config)
   PF_DB_PASS:       Database password, e.g. postfix (must match postfix container config)

Configuration technicalguru/rs-mailserver-roundcube:
====================================================
Environment Variables:
   RC_DB_HOST:       Service Name of database server, e.g. db-service (can be same as for PF and PFA)
   RC_DB_NAME:       Database name, e.g. roundcube (shall be different from PF and PFA)
   RC_DB_USER:       Database user, e.g. roundcube (shall be different from PF and PFA)
   RC_DB_PASS:       Database password, e.g. roundcube

Installation procedure:
=======================
1. Adjust your yaml files for services and deployments (environment variables, namespace)
   - Start with database config
1. Apply your yaml file to your Kubernetes cluster
1. Setup your Ingress controller as follows:
   - https://yourdomain.tld/mysql/        points to phpmyadmin-service
   - https://yourdomain.tld/postfixadmin/ points to postfix-service
   - https://yourdomain.tld/roundcube/    points to roundcube-service
   - Create a SSL certificate and terminate SSL at the Ingress controller
1. Set your MX record accordingly
1. Open the PhpMyAdmin page at https://yourdomain.tld/mysql/ and login with your root user
   1. Create the PF user and the PF database. Grant privileges on the DB to your PF user
   1. Create the Roundcube user and the Roundcube database. Grant privileges on this DB to your user
1. Open the PostfixAdmin Installer at https://yourdomain.tld/postfixadmin/public/setup.php
   - Follow the setup instructions and create your PFA user
1. Open the PostfixAdmin at https://yourdomain.tld/postfixadmin/public/ now and login with your PFA user
   - Create your TLD and your mailboxes
1. Open Roundcube WebMail Installer at https://yourdomain.tld/roundcube/installer/
   - Enable the installer by logging into a bash at the pod container and editing last line in /var/www/html/config/config.inc.php
   - Check your setup and install/upgrade your installation
   - Disable the installer again by editing last line in /var/www/html/config/config.inc.php
1. Open Roundcube WebMail https://yourdomain.tld/roundcube/
   - Login to your mailbox
   - Test internal mail communications and external mail communication to/from your new server

Congratulations! You are done!

