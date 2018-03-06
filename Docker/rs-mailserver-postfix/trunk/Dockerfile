FROM debian
MAINTAINER Ralph Schuster <github@ralph-schuster.eu>

RUN apt-get update && apt-get install -y --no-install-recommends \
    postfix \
    mailutils \
	vim \
    rsyslog \
    dnsutils \
    telnet \
    && rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/postfix/main.cf /etc/postfix/master.cf /etc/aliases

RUN mkdir /usr/local/rs-mailserver \
    && mkdir /usr/local/rs-mailserver/bin \
    && mkdir /usr/local/rs-mailserver/postfix

COPY src/bin/* /usr/local/rs-mailserver/bin/
COPY src/postfix/* /usr/local/rs-mailserver/postfix/

RUN chmod 755 /usr/local/rs-mailserver/bin/*

WORKDIR /usr/local/rs-mailserver/bin
CMD ["/usr/local/rs-mailserver/bin/exec-server.sh"]
