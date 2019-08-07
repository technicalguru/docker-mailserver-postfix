FROM debian:buster
MAINTAINER Ralph Schuster <github@ralph-schuster.eu>

RUN debconf-set-selections << "postfix postfix/mailname string mail.example.com" 
RUN debconf-set-selections << "postfix postfix/main_mailer_type string 'Internet Site'"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    mysql-client \
    postfix postfix-mysql \
    dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql dovecot-sieve dovecot-managesieved dovecot-antispam \
    mailutils \
	vim \
    rsyslog \
    dnsutils \
    telnet \
    opendkim opendkim-tools \
    && rm -rf /var/lib/apt/lists/*

RUN rm -rf /etc/postfix/* /etc/aliases /etc/dovecot/* /etc/opendkim.conf

RUN mkdir /usr/local/rs-mailserver \
    && mkdir /usr/local/rs-mailserver/bin \
    && mkdir /usr/local/rs-mailserver/postfix \
    && mkdir /usr/local/rs-mailserver/dovecot \
    && mkdir /usr/local/rs-mailserver/sql \
    && mkdir /etc/postfix/sql \
    && mkdir /etc/opendkim \
    && mkdir /etc/opendkim/keys \
    && mkdir /var/vmail \
    && mkdir /var/vmail/sieve \
    && mkdir /var/vmail/sieve/global 


COPY src/bin/ /usr/local/rs-mailserver/bin/
COPY src/postfix/ /usr/local/rs-mailserver/postfix/
COPY src/dovecot/ /usr/local/rs-mailserver/dovecot/
COPY src/sieve/ /var/vmail/sieve/global/

RUN touch /etc/postfix/postscreen_access \
    && touch /etc/postfix/without_ptr \
    && adduser --gecos --disabled-login --disabled-password --home /var/vmail vmail \
    && chmod 755 /usr/local/rs-mailserver/bin/* \
    && chown vmail:vmail /usr/local/rs-mailserver/bin/spampipe.sh \
    && mkdir /var/vmail/mailboxes \
    && mkdir -p /var/vmail/sieve/global \
    && chown -R vmail:vmail /var/vmail \
    && chmod -R 770 /var/vmail \
    && cd /etc/opendkim \
    && opendkim-genkey --selector=key1 --bits=2048 --directory=keys \
    && chown opendkim /etc/opendkim/keys/key1.private \
    && usermod -aG opendkim postfix

WORKDIR /usr/local/rs-mailserver/bin
CMD ["/usr/local/rs-mailserver/bin/exec-server.sh"]
