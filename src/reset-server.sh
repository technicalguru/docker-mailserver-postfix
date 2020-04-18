#!/bin/bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin
DAEMON=/usr/sbin/postfix
NAME=Postfix
IMAGE_HOME=/usr/local/mailserver
IMAGE_TEMPLATES=$IMAGE_HOME/templates
TZ=
unset TZ

test -f /etc/default/postfix && . /etc/default/postfix

cd $IMAGE_TEMPLATES/postfix
for file in *; do mv /etc/postfix/$file /etc/postfix/$file.bak 2>/dev/null; done

cd $IMAGE_TEMPLATES/sql
for file in *; do mv /etc/postfix/sql/$file /etc/postfix/sql/$file.bak 2>/dev/null; done

cd $IMAGE_TEMPLATES/dovecot
for file in *; do mv /etc/dovecot/$file /etc/dovecot/$file.bak 2>/dev/null; done

cd $IMAGE_TEMPLATES/dovecot-conf-d
for file in *; do mv /etc/dovecot/conf.d/$file /etc/dovecot/conf.d/$file.bak 2>/dev/null; done

mv /etc/aliases /etc/aliases.bak 

exit 0

