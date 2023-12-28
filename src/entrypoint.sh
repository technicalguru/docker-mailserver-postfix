#!/bin/bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin
DAEMON=/usr/sbin/postfix
NAME=Postfix
IMAGE_HOME=/usr/local/mailserver
IMAGE_TEMPLATES=$IMAGE_HOME/templates

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
if [[ -z "${PF_AMAVIS_SERVICE_PORT}" ]]; then
	PF_AMAVIS_SERVICE_PORT=10024
fi
if [[ -z "${PF_DKIM_SERVICE_PORT}" ]]; then
	PF_DKIM_SERVICE_PORT=41001
fi
if [[ -z "${PF_TLS_CERT_FILE}" ]]; then
	PF_TLS_CERT_FILE=/etc/ssl/certs/ssl-cert-snakeoil.pem
fi
if [[ -z "${PF_TLS_CERTCHAIN_FILE}" ]]; then
	PF_TLS_CERTCHAIN_FILE=${PF_TLS_CERT_FILE}
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
if [ ! -f $PF_TLS_CAFILE ]; then
	echo "PF_TLS_CAFILE=$PF_TLS_CAFILE: File does not exist" 1>&2
fi
if [ ! -d $PF_TLS_CAPATH ]; then
	echo "PF_TLS_CAPATH=$PF_TLS_CAPATH: Directory does not exist" 1>&2
fi
if [[ -z "${PF_TLS_ADMIN_EMAIL}" ]]; then
	PF_TLS_ADMIN_EMAIL="postmaster\@${PF_MYDOMAIN}"
fi
if [[ -z "${PF_ENABLE_UTF8}" ]]; then
	PF_ENABLE_UTF8=yes
fi
if [[ -z "${PF_MILTERS}" ]]; then
	PF_MILTERS=
fi
####################
# Helper functions
####################
# Replace a variable ina file
# Arguments:
# $1 - file to replace variable in
# $2 - Name of variable to be replaced
# $3 - Value to replace
replace_var() {
	# assign vars
	VARNAME=$2
	VARVALUE=${!VARNAME}
	# Sanitize for sed regex
	VARVALUE="${VARVALUE//:/\\:}"
	# replace with sed
	sed -i "s:__${VARNAME}__:${VARVALUE}:g" $1
}

# Copy a template file and replace all variables in there.
# The target file will not be touched if it exists before
# Arguments:
# $1 - the template file
# $2 - the destination file
copy_template_file() {
	TMP_SRC=$1
	TMP_DST=$2

	if [ ! -f $TMP_DST ]; then
		if [ ! -f $TMP_SRC ]; then
			echo "Cannot find $TMP_SRC" 1>&2
			exit 1
		fi
		echo "Creating $TMP_DST from template $TMP_SRC"
		cp $TMP_SRC $TMP_DST
		replace_var $TMP_DST 'PF_MYDOMAIN'
		replace_var $TMP_DST 'PF_MYHOSTNAME'
		replace_var $TMP_DST 'PF_MYORIGIN'
		replace_var $TMP_DST 'PF_AMAVIS_CONTENT_FILTER'
		replace_var $TMP_DST 'PF_TLS_CERT_FILE'
		replace_var $TMP_DST 'PF_TLS_CERTCHAIN_FILE'
		replace_var $TMP_DST 'PF_TLS_KEY_FILE'
		if [ ! -f $PF_TLS_CAFILE ]; then
			sed -i "s/^.*PF_TLS_CAFILE__/# PF_TLS_CAFILE does not exist/g" $TMP_DST
		else
			replace_var $TMP_DST 'PF_TLS_CAFILE'
		fi
		if [ ! -d $PF_TLS_CAPATH ]; then
			sed -i "s/^.*PF_TLS_CAPATH__/# PF_TLS_CAPATH does not exist/g" $TMP_DST
		else
			replace_var $TMP_DST 'PF_TLS_CAPATH'
		fi
		replace_var $TMP_DST 'PF_DB_HOST'
		replace_var $TMP_DST 'PF_DB_NAME'
		replace_var $TMP_DST 'PF_DB_USER'
		replace_var $TMP_DST 'PF_DB_PASS'
		replace_var $TMP_DST 'PF_ENABLE_UTF8'
		replace_var $TMP_DST 'PF_MILTERS'
	fi
	if [ ! -f $TMP_DST ]; then
		echo "Cannot create $TMP_DST" 1>&2
		exit 1
	fi
}

# Copy template files in a directory to a destination directory
copy_files() {
	SRC=$1
	DST=$2
	cd $SRC
	for file in *
	do
		copy_template_file $SRC/$file $DST/$file
	done
}

# Configure postfix.
# Makes sure all postfix config files are in place
configure_postfix() {
	# Check the presence of Amavis
	if [ -z "${PF_AMAVIS_SERVICE_NAME}" ]
	then
		# No Amavis configured
		export PF_AMAVIS_CONTENT_FILTER=""
	else
		# Amavis configured
		export PF_AMAVIS_CONTENT_FILTER="amavis:[${PF_AMAVIS_SERVICE_NAME}]:${PF_AMAVIS_SERVICE_PORT}"
	fi

	# Check the presence of milters and DKIM
	if [ -z "${PF_MILTERS}" ]
	then
		if [ -z "${PF_DKIM_SERVICE_NAME}" ]
		then
			# No Milter
			export PF_MILTERS=""
		else
			# Milter 
			export PF_MILTERS="inet:${PF_DKIM_SERVICE_NAME}:${PF_DKIM_SERVICE_PORT}"
		fi
	fi

	# POSTFIX
	copy_files $IMAGE_TEMPLATES/postfix /etc/postfix/

	# ALIASES
	copy_template_file $IMAGE_TEMPLATES/aliases/aliases /etc/aliases

	# DOVECOT
	copy_files $IMAGE_TEMPLATES/dovecot /etc/dovecot
	copy_files $IMAGE_TEMPLATES/dovecot-conf-d /etc/dovecot/conf.d

	# SQL CONFIGS
	copy_files $IMAGE_TEMPLATES/sql /etc/postfix/sql
	chmod -R 640 /etc/postfix/sql

	# Generate the EDH parameters
	cd /etc/postfix
	openssl dhparam -out dh512.tmp 512 && mv dh512.tmp dh512.pem
	openssl dhparam -out dh1024.tmp 1024 && mv dh1024.tmp dh1024.pem
	openssl dhparam -out dh2048.tmp 2048 && mv dh2048.tmp dh2048.pem
	chmod 644 dh512.pem dh1024.pem dh2048.pem
	cd $IMAGE_HOME

	postmap /etc/postfix/without_ptr 
	newaliases
}

# Make sure that all configurations match for postfix
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

check_database_user() {
	USER=$( echo "select host,user from mysql.user where user='$PF_DB_USER';" | mysql -u root --password=$PF_SETUP_PASS -h $PF_DB_HOST --skip-column-names)
	if [[ -z "$USER" ]]
	then
		# Create user
		echo "Creating user..."
		echo "CREATE USER '$PF_DB_USER'@'%' IDENTIFIED BY '$PF_DB_PASS';" | mysql -u root --password=$PF_SETUP_PASS -h $PF_DB_HOST
		if [[ $? -ne 0 ]]
		then
			echo "Cannot create user $PF_DB_USER" 1>&2
			exit 1
		fi
	fi
}

create_database() {
	echo "Creating database..."
	echo "CREATE DATABASE IF NOT EXISTS $PF_DB_NAME;" |  mysql -u root --password=$PF_SETUP_PASS -h $PF_DB_HOST
	if [[ $? -ne 0 ]]
	then
		echo "Cannot create database $PF_DB_NAME" 1>&2
		exit 1
	fi
	# Also authorize user now
	echo "Granting privileges..."
	echo "GRANT ALL PRIVILEGES ON \`$PF_DB_NAME\`.* TO '$PF_DB_USER'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;" | mysql -u root --password=$PF_SETUP_PASS -h $PF_DB_HOST
	if [[ $? -ne 0 ]]
	then
		echo "Cannot grant privileges on database $PF_DB_NAME to user $PF_DB_USER" 1>&2
		exit 1
	fi
	# we need some delay for the privileges to be flushed
	sleep 2
}

create_tables() {
	mysql -u $PF_DB_USER --password=$PF_DB_PASS -h $PF_DB_HOST $PF_DB_NAME <$IMAGE_HOME/create_tables.sql
	if [[ $? -ne 0 ]]
	then
		echo "Cannot create tables on database $PF_DB_NAME to user $PF_DB_USER" 1>&2
		exit 1
	fi
}

check_database() {
	TABLES=$( echo "show tables;" | mysql -u $PF_DB_USER --password=$PF_DB_PASS -h $PF_DB_HOST --skip-column-names $PF_DB_NAME)
	if [[ -z "$TABLES" ]]
	then
		# Password not correct or database not initialized
		if [[ -z "$PF_SETUP_PASS" ]]
		then
			echo "Cannot check database setup. Your database denies access. Cannot proceed as there is no setup password provided (PF_SETUP_PASS)" 1>&2
			exit 1
		fi

		# Make sure that user is created
		check_database_user

		# Try to list the database
		DATABASES=$( echo "show databases like '$PF_DB_NAME';" | mysql -u root --password=$PF_SETUP_PASS -h $PF_DB_HOST --skip-column-names)
		if [[ $? -ne 0 ]]
		then
			echo "Cannot check database setup. Please check your database setup!" 1>&2
			exit 1
		fi

		# Check that $PF_DB_NAME is in the list of databases
		if [[ -z "$DATABASES" ]]
		then
			# No database yet
			create_database
		fi

	fi

	# will only create when not existing yet
	create_tables
}

configure_sieve() {
	if [ ! -d /var/vmail/sieve/global ]
	then
		mkdir --parent /var/vmail/sieve/global
	fi
	if [ ! -f /var/vmail/sieve/global/spam-global.sieve ]
	then
		cp $IMAGE_TEMPLATES/sieve/spam-global.sieve /var/vmail/sieve/global/spam-global.sieve
	fi
	chown -R vmail:vmail /var/vmail/sieve
}

# Stopping all (we got a TERM signal at this point)
_sigterm() {
	echo "Caught SIGTERM..."
	/usr/sbin/postfix stop
	service dovecot stop
	service rsyslog stop
	kill -TERM "$TAIL_CHILD_PID" 2>/dev/null
}

#########################
# Installation check
#########################
check_database

#########################
# Startup procedure
#########################
cd $IMAGE_HOME

# Configure Sieve rule
configure_sieve

# Configure postfix
configure_postfix
configure_instance -
postconf compatibility_level=2
postconf maillog_file=/var/log/mail.log

# Start Dovecot (the mail drop software)
service dovecot start

# Start Postfix in foreground (for logging purposes)
/usr/sbin/postfix start

# Tail the mail.log
trap _sigterm SIGTERM

tail -f /var/log/mail.log &
TAIL_CHILD_PID=$!

if [ -f $PF_TLS_CERT_FILE ]
then
	# Entering endless loop for Certificate check every 24 hours
	INTERVAL=86400
	COUNTDOWN=0
	DAYS=10
	while kill -0 $TAIL_CHILD_PID >/dev/null 2>&1
	do
		if [ "$COUNTDOWN" -le 0 ]
		then
			echo "Checking TLS certificate..."
			openssl x509 -checkend $(( 86400 * $DAYS )) -enddate -in "$PF_TLS_CERT_FILE"
			EXPIRY=$?
			if [ $EXPIRY -ne 0 ]; then
				echo "Certificate will expire within 10 days. Sending notification..."
				sendmail $PF_TLS_ADMIN_EMAIL <<EOM
To: $PF_TLS_ADMIN_EMAIL
From: postfix@$PF_MYDOMAIN
Subject: Postfix TLS certificate expires within 10 days

Hello Postmaster,

the TLS certificate at $PF_MYHOSTNAME is about to expire within 10 days.
Please renew it.

_____
This message was automatically sent from Mailserver Postfix system at $PF_MYHOSTNAME.
.

EOM
				echo "Notification sent."
			fi
			COUNTDOWN=$INTERVAL
		fi
		sleep 1
		((COUNTDOWN=COUNTDOWN-1))
	done
else
	wait "$TAIL_CHILD_PID"
fi



