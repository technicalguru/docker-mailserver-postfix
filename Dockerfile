FROM debian:10.2
MAINTAINER Ralph Schuster <github@ralph-schuster.eu>

RUN echo "postfix postfix/mailname string mail.example.com" | debconf-set-selections
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y --no-install-recommends \
    default-mysql-client \
    apt-utils \
    procps \
    postfix postfix-mysql \
    dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql dovecot-sieve dovecot-managesieved dovecot-antispam \
    mailutils \
	vim \
    rsyslog \
    dnsutils \
    telnet \
    opendkim opendkim-tools \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /usr/local/mailserver \
    && mkdir /usr/local/mailserver/templates \
    && mkdir /usr/local/mailserver/templates/postfix \
    && mkdir /usr/local/mailserver/templates/dovecot \
    && mkdir /usr/local/mailserver/templates/sql \
    && mkdir /usr/local/mailserver/templates/aliases \
    && mkdir /etc/postfix/sql \
    && mkdir /etc/opendkim \
    && mkdir /etc/opendkim/keys \
    && mkdir /var/vmail \
    && mkdir /var/vmail/sieve \
    && mkdir /var/vmail/sieve/global 


ADD src/ /usr/local/mailserver/
ADD etc/sql/ /usr/local/mailserver/templates/sql/
ADD etc/postfix/ /usr/local/mailserver/templates/postfix/
ADD etc/dovecot/ /usr/local/mailserver/templates/dovecot/
ADD etc/aliases/ /usr/local/mailserver/templates/aliases/
ADD etc/sieve/ /var/vmail/sieve/global/

RUN chmod 755 /usr/local/mailserver/*.sh \
    && sync \
    && /usr/local/mailserver/reset-server.sh \
    && touch /etc/postfix/postscreen_access \
    && touch /etc/postfix/without_ptr \
    && adduser --gecos --disabled-login --disabled-password --home /var/vmail vmail \
    && chown vmail:vmail /usr/local/mailserver/spampipe.sh \
    && mkdir /var/vmail/mailboxes \
    && mkdir -p /var/vmail/sieve/global \
    && chown -R vmail:vmail /var/vmail \
    && chmod -R 770 /var/vmail \
    && cd /etc/opendkim \
    && opendkim-genkey --selector=key1 --bits=2048 --directory=keys \
    && chown opendkim /etc/opendkim/keys/key1.private \
    && usermod -aG opendkim postfix

WORKDIR /usr/local/mailserver
#CMD ["/usr/local/mailserver/loop.sh"]
CMD ["/usr/local/mailserver/entrypoint.sh"]

