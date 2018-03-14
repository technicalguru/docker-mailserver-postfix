#!/bin/bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin

if [[ -z "${PF_DB_HOST}" ]]; then
	PF_DB_HOST=localhost
fi
if [[ -z "${PF_DB_NAME}" ]]; then
	PF_DB_NAME=postfix
fi
if [[ -z "${PF_DB_USER}" ]]; then
	PF_DB_USER=postfix
fi
if [[ -z "${PF_DB_PASS}" ]]; then
	PF_DB_PASS=password
fi

replace_var() {
	VARNAME=$2
	sed -i "s~__$2__~${!VARNAME}~g" $1
}

copy_template_file() {
	TMP_SRC=$1
    TMP_DST=$2

	if [ ! -f $TMP_DST ]; then
		cp $TMP_SRC $TMP_DST
		replace_var $TMP_DST 'PF_DB_HOST'
		replace_var $TMP_DST 'PF_DB_NAME'
		replace_var $TMP_DST 'PF_DB_USER'
		replace_var $TMP_DST 'PF_DB_PASS'
	fi
}

copy_template_file '/usr/local/rs-mailserver/postfix/sql/tables.template' '/usr/local/rs-mailserver/postfix/sql/tables.sql'

cat /usr/local/rs-mailserver/postfix/sql/tables.sql


