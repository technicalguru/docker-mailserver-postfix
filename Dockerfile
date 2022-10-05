FROM debian:11
LABEL maintainer="Ralph Schuster <github@ralph-schuster.eu>"

RUN echo "postfix postfix/mailname string mail.example.com" | debconf-set-selections
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

ENV PF_VERSION="3.5.13"
ENV PF_REVISION="1"
RUN export DEBIAN_FRONTEND=noninteractive \
    && PF_VERSION=3.5.13-0+deb11u1 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    default-mysql-client \
    apt-utils \
    procps \
    postfix=${PF_VERSION} \
    postfix-mysql=${PF_VERSION} \
    dovecot-core \
    dovecot-imapd \
    dovecot-pop3d \
    dovecot-lmtpd \
    dovecot-mysql \
    dovecot-sieve \
    dovecot-managesieved \
    dovecot-antispam \
    mailutils \
	vim \
    rsyslog \
    dnsutils \
    telnet \
    opendkim \
    opendkim-tools \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /usr/local/mailserver \
    && mkdir /usr/local/mailserver/templates \
    && mkdir /usr/local/mailserver/templates/postfix \
    && mkdir /usr/local/mailserver/templates/dovecot \
    && mkdir /usr/local/mailserver/templates/dovecot-conf-d \
    && mkdir /usr/local/mailserver/templates/sieve \
    && mkdir /usr/local/mailserver/templates/sql \
    && mkdir /usr/local/mailserver/templates/aliases \
    && mkdir /etc/postfix/sql \
    && mkdir /etc/opendkim \
    && mkdir /etc/opendkim/keys \
    && mkdir /var/vmail 


ADD src/ /usr/local/mailserver/
ADD etc/postfix/ /usr/local/mailserver/templates/postfix/
ADD etc/dovecot/ /usr/local/mailserver/templates/dovecot/
ADD etc/dovecot-conf-d/ /usr/local/mailserver/templates/dovecot-conf-d/
ADD etc/sieve/ /usr/local/mailserver/templates/sieve/
ADD etc/aliases/ /usr/local/mailserver/templates/aliases/
ADD etc/sql/ /usr/local/mailserver/templates/sql/

RUN chmod 755 /usr/local/mailserver/*.sh \
    && sync \
    && /usr/local/mailserver/reset-server.sh \
    && touch /etc/postfix/postscreen_access \
    && touch /etc/postfix/without_ptr \
    && adduser --gecos --disabled-login --disabled-password --home /var/vmail vmail \
    && chown vmail:vmail /usr/local/mailserver/spampipe.sh \
    && mkdir /var/vmail/mailboxes \
    && chown -R vmail:vmail /var/vmail \
    && chmod -R 770 /var/vmail \
    && cd /etc/opendkim \
    && opendkim-genkey --selector=key1 --bits=2048 --directory=keys \
    && chown opendkim /etc/opendkim/keys/key1.private \
    && usermod -aG opendkim postfix

#####################################################################
#  Image OCI labels
#####################################################################
ARG ARG_CREATED
ARG ARG_URL=https://github.com/technicalguru/docker-mailserver-postfix
ARG ARG_SOURCE=https://github.com/technicalguru/docker-mailserver-postfix
ARG ARG_VERSION="${PF_VERSION}.${PF_REVISION}"
ARG ARG_REVISION="${PF_REVISION}"
ARG ARG_VENDOR=technicalguru
ARG ARG_TITLE=technicalguru/mailserver-postfix
ARG ARG_DESCRIPTION="Provides Postfix/Dovecot MTA/MDA based on Debian with MySQL backend"
ARG ARG_DOCUMENTATION=https://github.com/technicalguru/docker-mailserver-postfix
ARG ARG_AUTHORS=technicalguru
ARG ARG_LICENSES=GPL-3.0-or-later

LABEL org.opencontainers.image.created=$ARG_CREATED
LABEL org.opencontainers.image.url=$ARG_URL
LABEL org.opencontainers.image.source=$ARG_SOURCE
LABEL org.opencontainers.image.version=$ARG_VERSION
LABEL org.opencontainers.image.revision=$ARG_REVISION
LABEL org.opencontainers.image.vendor=$ARG_VENDOR
LABEL org.opencontainers.image.title=$ARG_TITLE
LABEL org.opencontainers.image.description=$ARG_DESCRIPTION
LABEL org.opencontainers.image.documentation=$ARG_DOCUMENTATION
LABEL org.opencontainers.image.authors=$ARG_AUTHORS
LABEL org.opencontainers.image.licenses=$ARG_LICENSES

#####################################################################
#  Running the container
#####################################################################
WORKDIR /usr/local/mailserver
# SMTP Port
EXPOSE 25
# POP3 Port
EXPOSE 110
# IMAP Port
EXPOSE 143
# SMTPS Port
EXPOSE 587
# IMAPS Port
EXPOSE 993
# POP3S Port
EXPOSE 995
# SMTP Port (used for internal delivery from amavis, do not expose to the outside world!)
EXPOSE 10025
#CMD ["/usr/local/mailserver/loop.sh"]
CMD ["/usr/local/mailserver/entrypoint.sh"]

