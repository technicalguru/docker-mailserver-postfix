#!/bin/bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin
DAEMON=/usr/sbin/postfix
NAME=Postfix
TZ=
unset TZ

test -f /etc/default/postfix && . /etc/default/postfix

rm /etc/postfix/master.cf 
rm /etc/postfix/main.cf 
rm /etc/postfix/submission_header_cleanup 
rm /etc/aliases /etc/dovecot/dovecot.conf 
rm /etc/dovecot/dovecot-sql.conf 
rm /etc/postfix/sql/accounts.cf 
rm /etc/postfix/sql/aliases.cf 
rm /etc/postfix/sql/domains.cf 
rm /etc/postfix/sql/recipient-access.cf 
rm /etc/postfix/sql/sender-login-maps.cf 
rm /etc/postfix/sql/tls-policy.cf 
