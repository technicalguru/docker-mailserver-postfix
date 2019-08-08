#!/bin/bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin
DAEMON=/usr/sbin/postfix
NAME=Postfix
TZ=
unset TZ

# Defaults - don't touch, edit /etc/default/postfix
SYNC_CHROOT="y"

test -f /etc/default/postfix && . /etc/default/postfix

test -x $DAEMON  || exit 0

# Check env vars
if [[ -z "${PF_MYDOMAIN}" ]]; then
	PF_MYDOMAIN=localdomain
fi
if [[ -z "${PF_MYHOSTNAME}" ]]; then
	PF_MYHOSTNAME=$(hostname -f)
fi
if [[ -z "${PF_MYORIGIN}" ]]; then
	PF_MYORIGIN=$PF_MYHOSTNAME
fi
if [[ -z "${PF_TLS_CERT_FILE}" ]]; then
	PF_TLS_CERT_FILE=/etc/ssl/certs/ssl-cert-snakeoil.pem
fi
if [[ -z "${PF_TLS_KEY_FILE}" ]]; then
	PF_TLS_KEY_FILE=/etc/ssl/private/ssl-cert-snakeoil.key
fi
if [[ -z "${PF_TLS_CAFILE}" ]]; then
	PF_TLS_CAFILE=/etc/postfix/CAcert.pem
fi
if [[ -z "${PF_TLS_CAPATH}" ]]; then
	PF_TLS_CAPATH=/etc/ssl/certs
fi
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
	VARVALUE=${!VARNAME}
	sed -i "s:__${VARNAME}__:${VARVALUE}:g" $1
}

copy_template_file() {
	TMP_SRC=$1
	TMP_DST=$2

	if [ ! -f $TMP_DST ]; then
		if [ ! -f $TMP_SRC ]; then
			echo "Cannot find $TMP_SRC"
			exit 1
		fi
		cp $TMP_SRC $TMP_DST
		replace_var $TMP_DST 'PF_MYDOMAIN'
		replace_var $TMP_DST 'PF_MYHOSTNAME'
		replace_var $TMP_DST 'PF_MYORIGIN'
		replace_var $TMP_DST 'PF_TLS_CERT_FILE'
		replace_var $TMP_DST 'PF_TLS_KEY_FILE'
		if [ ! -f $PF_TLS_CAFILE ]; then
			sed -i "s/^.*PF_TLS_CAFILE/# PF_TLS_CAFILE does not exist/g" $TMP_DST
		else
			replace_var $TMP_DST 'PF_TLS_CAFILE'
		fi
		if [ ! -f $PF_TLS_CAPATH ]; then
			sed -i "s/^.*PF_TLS_CAPATH/# PF_TLS_CAPATH does not exist/g" $TMP_DST
		else
			replace_var $TMP_DST 'PF_TLS_CAPATH'
		fi
		replace_var $TMP_DST 'PF_DB_HOST'
		replace_var $TMP_DST 'PF_DB_NAME'
		replace_var $TMP_DST 'PF_DB_USER'
		replace_var $TMP_DST 'PF_DB_PASS'
	fi
	if [ ! -f $TMP_DST ]; then
		echo "Cannot create $TMP_DST"
		exit 1
	fi
}

configure_postfix() {
	# POSTFIX
	copy_template_file '/usr/local/rs-mailserver/postfix/master.cf' '/etc/postfix/master.cf'
	copy_template_file '/usr/local/rs-mailserver/postfix/main.cf' '/etc/postfix/main.cf'
	copy_template_file '/usr/local/rs-mailserver/postfix/dynamicmaps.cf' '/etc/postfix/dynamicmaps.cf'
	copy_template_file '/usr/local/rs-mailserver/postfix/submission_header_cleanup' '/etc/postfix/submission_header_cleanup'

	# ALIASES
	copy_template_file '/usr/local/rs-mailserver/postfix/aliases' '/etc/aliases'

	# DOVECOT
	copy_template_file '/usr/local/rs-mailserver/dovecot/dovecot.conf' '/etc/dovecot/dovecot.conf'
	copy_template_file '/usr/local/rs-mailserver/dovecot/dovecot-sql.conf' '/etc/dovecot/dovecot-sql.conf'

	# SQL CONFIGS
	copy_template_file '/usr/local/rs-mailserver/postfix/sql/accounts.cf' '/etc/postfix/sql/accounts.cf'
	copy_template_file '/usr/local/rs-mailserver/postfix/sql/aliases.cf' '/etc/postfix/sql/aliases.cf'
	copy_template_file '/usr/local/rs-mailserver/postfix/sql/domains.cf' '/etc/postfix/sql/domains.cf'
	copy_template_file '/usr/local/rs-mailserver/postfix/sql/recipient-access.cf' '/etc/postfix/sql/recipient-access.cf'
	copy_template_file '/usr/local/rs-mailserver/postfix/sql/sender-login-maps.cf' '/etc/postfix/sql/sender-login-maps.cf'
	copy_template_file '/usr/local/rs-mailserver/postfix/sql/tls-policy.cf' '/etc/postfix/sql/tls-policy.cf'
	copy_template_file '/usr/local/rs-mailserver/sql/tables.template' '/usr/local/rs-mailserver/sql/tables.sql'
	chmod -R 660 /etc/postfix/sql

	postmap /etc/postfix/without_ptr 
	newaliases
}

configure_instance() {
	INSTANCE="$1"
    if [ "X$INSTANCE" = X ]; then
            POSTCONF="postconf"
    else
            POSTCONF="postmulti -i $INSTANCE -x postconf"
    fi


    # if you set myorigin to 'ubuntu.com' or 'debian.org', it's wrong, and annoys the admins of
    # those domains.  See also sender_canonical_maps.

    MYORIGIN=$($POSTCONF -h myorigin | tr 'A-Z' 'a-z')
    if [ "X${MYORIGIN#/}" != "X${MYORIGIN}" ]; then
        MYORIGIN=$(tr 'A-Z' 'a-z' < $MYORIGIN)
    fi
    if [ "X$MYORIGIN" = Xubuntu.com ] || [ "X$MYORIGIN" = Xdebian.org ]; then
        log_failure_msg "Invalid \$myorigin ($MYORIGIN), refusing to start"
        log_end_msg 1
        exit 1
    fi

    config_dir=$($POSTCONF -h config_directory)
    # see if anything is running chrooted.
    NEED_CHROOT=$(awk '/^[0-9a-z]/ && ($5 ~ "[-yY]") { print "y"; exit}' ${config_dir}/master.cf)

	if [ -n "$NEED_CHROOT" ] && [ -n "$SYNC_CHROOT" ]; then
        # Make sure that the chroot environment is set up correctly.
        oldumask=$(umask)
        umask 022
        queue_dir=$($POSTCONF -h queue_directory)
        cd "$queue_dir"

        # copy the CA path if specified
        ca_path=$($POSTCONF -h smtp_tls_CApath)
        case "$ca_path" in
            '') :;; # no ca_path
            $queue_dir/*) :;;  # skip stuff already in chroot, (and to make vim syntax happy: */)
            *)
                if test -d "$ca_path"; then
                    dest_dir="$queue_dir/${ca_path#/}"
                    # strip any/all trailing /
                    while [ "${dest_dir%/}" != "${dest_dir}" ]; do
                        dest_dir="${dest_dir%/}"
                    done
                    new=0
                    if test -d "$dest_dir"; then
                        # write to a new directory ...
                        dest_dir="${dest_dir}.NEW"
                        new=1
                    fi
                    mkdir --parent ${dest_dir}
                    # handle files in subdirectories
                    (cd "$ca_path" && find . -name '*.pem' -print0 | cpio -0pdL --quiet "$dest_dir") 2>/dev/null ||
                        (log_failure_msg failure copying certificates; exit 1)
                    c_rehash "$dest_dir" >/dev/null 2>&1
                    if [ "$new" = 1 ]; then
                        # and replace the old directory
                        rm -rf "${dest_dir%.NEW}"
                        mv "$dest_dir" "${dest_dir%.NEW}"
                    fi
                fi
                ;;
        esac

        # if there is a CA file, copy it
        ca_file=$($POSTCONF -h smtp_tls_CAfile)
        case "$ca_file" in
            $queue_dir/*) :;;  # skip stuff already in chroot
            '') # no ca_file
                # or copy the bundle to preserve functionality
                ca_bundle=/etc/ssl/certs/ca-certificates.crt
                if [ -f $ca_bundle ]; then
                    mkdir --parent "$queue_dir/${ca_bundle%/*}"
                    cp -L "$ca_bundle" "$queue_dir/${ca_bundle%/*}"
                fi
                ;;
            *)
                if test -f "$ca_file"; then
                    dest_dir="$queue_dir/${ca_path#/}"
                    mkdir --parent "$dest_dir"
                    cp -L "$ca_file" "$dest_dir"
                fi
                ;;
        esac

        # if we're using unix:passwd.byname, then we need to add etc/passwd.
        local_maps=$($POSTCONF -h local_recipient_maps)
        if [ "X$local_maps" != "X${local_maps#*unix:passwd.byname}" ]; then
            if [ "X$local_maps" = "X${local_maps#*proxy:unix:passwd.byname}" ]; then
                sed 's/^\([^:]*\):[^:]*/\1:x/' /etc/passwd > etc/passwd
                chmod a+r etc/passwd
            fi
        fi

        FILES="etc/localtime etc/services etc/resolv.conf etc/hosts \
            etc/host.conf etc/nsswitch.conf etc/nss_mdns.config"
        for file in $FILES; do
            [ -d ${file%/*} ] || mkdir -p ${file%/*}
            if [ -f /${file} ]; then rm -f ${file} && cp /${file} ${file}; fi
            if [ -f  ${file} ]; then chmod a+rX ${file}; fi
        done
        # ldaps needs this. debian bug 572841
        (echo /dev/random; echo /dev/urandom) | cpio -pdL --quiet . 2>/dev/null || true
        rm -f usr/lib/zoneinfo/localtime
        mkdir -p usr/lib/zoneinfo
        ln -sf /etc/localtime usr/lib/zoneinfo/localtime

        LIBLIST=$(for name in gcc_s nss resolv; do
            for f in /lib/*/lib${name}*.so* /lib/lib${name}*.so*; do
               if [ -f "$f" ]; then  echo ${f#/}; fi;
            done;
        done)

        if [ -n "$LIBLIST" ]; then
            for f in $LIBLIST; do
                rm -f "$f"
            done
            tar cf - -C / $LIBLIST 2>/dev/null |tar xf -
        fi
        umask $oldumask
    fi
}

function get_state {
	echo $(script -c 'postfix status' | grep postfix/postfix-script)
}

service rsyslog start
configure_postfix
configure_instance -
/usr/sbin/postfix quiet-quick-start

while true; do
	state=$(get_state)
    if [[ "$state" != "${state/is running/}" ]]; then
        PID=${state//[^0-9]/}
        if [[ -z $PID ]]; then
            continue
        fi
        if [[ ! -d "/proc/$PID" ]]; then
            echo "Postfix process $PID does not exist."
            break
        fi
    else
        echo "Postfix is not running."
        break
    fi
	sleep 5
done

