FROM debian
MAINTAINER Ralph Schuster <github@ralph-schuster.eu>

RUN debconf-set-selections << "postfix postfix/mailname string mail.example.com" 
RUN debconf-set-selections << "postfix postfix/main_mailer_type string 'Internet Site'"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    postfix postfix-mysql \
    dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql dovecot-sieve dovecot-managesieved dovecot-antispam \
    mailutils \
	vim \
    rsyslog \
    dnsutils \
    telnet \
    && rm -rf /var/lib/apt/lists/*

RUN rm -rf /etc/postfix/* /etc/aliases /etc/dovecot/*

RUN mkdir /usr/local/rs-mailserver \
    && mkdir /usr/local/rs-mailserver/bin \
    && mkdir /usr/local/rs-mailserver/postfix \
    && mkdir /usr/local/rs-mailserver/dovecot \
    && mkdir /var/vmail \
    && mkdir /var/vmail/sieve \
    && mkdir /var/vmail/sieve/global 


ADD src/bin/ /usr/local/rs-mailserver/bin/
ADD src/postfix/ /usr/local/rs-mailserver/postfix/
ADD src/dovecot/ /usr/local/rs-mailserver/dovecot/
ADD src/sieve/ /var/vmail/sieve/global/

RUN touch /etc/postfix/postscreen_access \
    && touch /etc/postfix/without_ptr \
    && adduser --gecos --disabled-login --disabled-password --home /var/vmail vmail \
    && chmod 755 /usr/local/rs-mailserver/bin/* \
    && chown vmail:vmail /usr/local/rs-mailserver/bin/spampipe.sh \
    && mkdir /var/vmail/mailboxes \
    && mkdir -p /var/vmail/sieve/global \
    && chown -R vmail:vmail /var/vmail \
    && chmod -R 770 /var/vmail

WORKDIR /usr/local/rs-mailserver/bin
CMD ["/usr/local/rs-mailserver/bin/exec-server.sh"]
