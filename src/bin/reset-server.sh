#!/bin/bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin
DAEMON=/usr/sbin/postfix
NAME=Postfix
TZ=
unset TZ

test -f /etc/default/postfix && . /etc/default/postfix

mv /etc/postfix/master.cf /etc/postfix/master.cf.bak
mv /etc/postfix/main.cf /etc/postfix/main.cf.bak
rm /etc/postfix/submission_header_cleanup 
rm /etc/aliases /etc/dovecot/dovecot.conf 
rm /etc/dovecot/dovecot-sql.conf 
rm /etc/postfix/sql/accounts.cf 
rm /etc/postfix/sql/aliases.cf 
rm /etc/postfix/sql/domains.cf 
rm /etc/postfix/sql/recipient-access.cf 
rm /etc/postfix/sql/sender-login-maps.cf 
rm /etc/postfix/sql/tls-policy.cf 

exit 0

