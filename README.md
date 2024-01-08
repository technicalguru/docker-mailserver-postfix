# docker-mailserver-postfix
This is a Docker image for a Postfix/Dovecot mailserver. The project is part of the 
[docker-mailserver](https://github.com/technicalguru/docker-mailserver) project but can run separately 
without the other components. However, a database server is always required to store structural data. 
E-Mails itself are stored on file system.

Related images:
* [docker-mailserver](https://github.com/technicalguru/docker-mailserver) - The main project, containing composition instructions
* [docker-mailserver-opendkim](https://github.com/technicalguru/docker-mailserver-opendkim) - OpenDKIM image (DKIM signing milter component)
* [docker-mailserver-postfixadmin](https://github.com/technicalguru/docker-mailserver-postfixadmin) - Image for PostfixAdmin (Web UI to manage mailboxes and domain in Postfix)
* [docker-mailserver-amavis](https://github.com/technicalguru/docker-mailserver-amavis) - Amavis, ClamAV and SpamAssassin (provides spam and virus detection)
* [docker-mailserver-roundcube](https://github.com/technicalguru/docker-mailserver-roundcube) - Roundcube Webmailer

# Tags
The following versions are available from DockerHub. The image tag matches the Postfix version.

* [3.7.9.1, 3.7.9, 3.7, 3, latest](https://github.com/technicalguru/docker-mailserver-postfix/tree/v3.7.9.1) - [Dockerfile](https://github.com/technicalguru/docker-mailserver-postfix/blob/3.7.9.1/Dockerfile)
* [3.5.18.0, 3.5.18, 3.5](https://github.com/technicalguru/docker-mailserver-postfix/tree/v3.5.18.0) - [Dockerfile](https://github.com/technicalguru/docker-mailserver-postfix/blob/3.5.18.0/Dockerfile)
* [3.4.14.0, 3.4.14, 3.4](https://github.com/technicalguru/docker-mailserver-postfix/tree/v3.4.14.0) - [Dockerfile](https://github.com/technicalguru/docker-mailserver-postfix/blob/3.4.14.0/Dockerfile)

# Features
* Bootstrap from scratch: See more information below.
* Standard SMTP and IMAP ports
* TLS encryption (optional)
* AntiVirus and AntiSpam integration (optional)
* Moves spam into Spam folder of your mailbox automatically (when spam recognition is on)
* User-specific sieve rules enabled

# License
_docker-mailserver-postfix_  is licensed under [GNU LGPL 3.0](LICENSE.md). As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

# Prerequisites
The following components must be available at runtime:
* [MySQL >8.0](https://hub.docker.com/\_/mysql) or [MariaDB >10.4](https://hub.docker.com/\_/mariadb) - used as database backend for domains and mailboxes. 

# Usage

## Environment Variables
_mailserver-postfix_  requires various environment variables to be set. The container startup will fail when the setup is incomplete.

| **Variable** | **Description** | **Default Value** |
|------------|---------------|-----------------|
| `PF_SETUP_PASS` | The password of the database administrator (`root`). This value is required for the initial bootstrap only in order to setup the database structure. It can and shall be removed after successful setup. |  |
| `PF_DB_HOST` | The hostname or IP address of the database server | `localhost` |
| `PF_DB_USER` | The name of the database user. **Attention!** You shall not use an administrator account. | `postfix` |
| `PF_DB_PASS` | The password of the database user | `password` |
| `PF_DB_NAME` | The name of the database | `postfix` |
| `PF_MYDOMAIN` | The first and primary mail domain of this server. Postfix requires this for setup but you can configure multiple main domains. | `localdomain` |
| `PF_MYHOSTNAME` | The hostname that Postfix uses to greet clients. | (name of host) |
| `PF_MYORIGIN` | The domain to be used for local mails (usually name of host). | value of `PF_MYHOSTNAME` |
| `PF_AMAVIS_SERVICE_NAME` | The hostname or IP address of an Amavis instance in order to fight spam and viruses. No AntiSpam and AntiVirus detection takes place when left empty |  |
| `PF_AMAVIS_SERVICE_PORT` | The port of the Amavis instance. | `10024` |
| `PF_MILTERS` | Milters to be configured |  |
| `PF_DKIM_SERVICE_NAME`| Hostname or IP address of a DKIM service |  |
| `PF_DKIM_SERVICE_PORT`| Port of a DKIM service | `41001` |
| `PF_TLS_CERT_FILE` | SSL server certificate for TLS. | `/etc/ssl/certs/ssl-cert-snakeoil.pem` |
| `PF_TLS_CERTCHAIN_FILE` | SSL server certificate for TLS including certificate chain. | value of PF\_TLS\_CERT\_FILE |
| `PF_TLS_KEY_FILE` | Key file for SSL server certificate. | `/etc/ssl/certs/ssl-cert-snakeoil.key` |
| `PF_TLS_CAPATH` | Directory that contains trusted CA root certificates. | `/etc/ssl/certs` |
| `PF_TLS_CAFILE` | Name of single file that contains trusted CA root certificates. | `/etc/postfix/CAcert.pem` |
| `PF_TLS_ADMIN_EMAIL` | E-mail address to be notified when TLS certificate is about to expire (10 days) | `postmaster@$PF_MYDOMAIN` |

## Volumes
You need to provide data volumes in order to secure your mailboxes from data loss. 

* `/var/vmails` is required to persist e-mails that are locally delievered to a mailbox
* `/var/spool/postfix` is required to hold e-mails that are currently in transmission (Postfix mail queues). Ensure that it is writable for all at startup so Postfix, Dovecot and syslog can create their directories. Afterwards you can reduce the permissions to user-writable only.

Additional volumes are required to map your TLS certificate into the container.

## Ports
_docker-mailserver-postfix_  exposes 5 ports by default:
* Port 25 - the traditional SMTP port. This port must be accessible from other hosts to send e-mails to you.
* Port 110 - the port for incoming e-mails using POP3 protocol. You shall not use this port anymore
* Port 465 - the default port nowadays for SMTPS. Still, some mail providers do not support them. This port shall be accessible from other hosts.
* Port 587 - the default port nowadays for SMTP (STARTTLS enabled). Still, some mail providers do not support them. This port shall be accessible from other hosts.
* Port 143 - the default port for SMTP authentication and IMAP mail access. This port must be accessible for your mail agents, e.g. Outlook or Thunderbird.
* Port 993 - the port for incoming e-mails using IMAP protocol. This port must be accessible for your mail agents, e.g. Outlook or Thunderbird.
* Port 995 - the port for incoming e-mails using POP3S protocol. This port must be accessible for your mail agents, e.g. Outlook or Thunderbird.
* Port 10025 - a local SMTP delivery port for mails that were checked from Amavis. **Attention!** You need to make sure that this port is not accessible by any other host than your Amavis service because it is not protected and can be used for SPAM attacks.
 
## Running the Container
The [main mailserver project](https://github.com/technicalguru/docker-mailserver) has examples of container configurations:
* [with docker-compose](https://github.com/technicalguru/docker-mailserver/tree/master/examples/docker-compose)
* [with Kubernetes YAML files](https://github.com/technicalguru/docker-mailserver/tree/master/examples/kubernetes)
* [with HELM charts](https://github.com/technicalguru/docker-mailserver/tree/master/examples/helm-charts)

## Bootstrap and Setup
Once you have started your Postfix container successfully, it is now time to perform the first-time setup for your mailserver. It is highly recommended to use [docker-mailserver-postfixadmin](https://github.com/technicalguru/docker-mailserver-postfixadmin) for this purpose. However, you can use your own [PostfixAdmin](https://github.com/postfixadmin/postfixadmin) installation.

1. Create your PostfixAdmin administrator account (see [docker-mailserver-postfixadmin](https://github.com/technicalguru/docker-mailserver-postfixadmin/blob/master/README.md))
1. Create your primary domain matching the environment variable `PF_MYDOMAIN`
1. Create your first mailbox in this domain

# TLS Configuration
Only two environment variables are required in order to secure your mailserver by TLS. `PF_TLS_CERT_FILE` and `PF_TLS_KEY_FILE` will ensure that mails can be sent to you in a secure way. However, bear in mind that these certificates expire. The system checks your TLS certificate every 24 hours and informs you by e-mail about the expiration. As the TLS variables hold path names only, it is required to map your certificate files into the running container using volumes.

You'll need to issue `postconfig reload` after you've changed the certificate. 

# Additional Postfix/Dovecot customization
You can further customize `main.cf`, `master.cf` and other Postfix configuration files. Please follow these instructions:

1. Check the `/usr/local/mailserver/templates` folder for already existing customizations. 
1. If you configuration file is not present yet, take a copy of the file from `/etc/postfix` folder.
1. Customize your Postfix and/or Dovecot configuration file.
1. Provide your customized file(s) back into the appropriate template folder at `/usr/local/mailserver/templates` by using volume mappings.
1. (Re)Start the container. If you configuration was not copied correctly then log into the container (bash is available) and issue `/usr/local/mailserver/reset-server.sh`. Then restart again.

# Testing your Mailserver

Here are some useful links that help you to test whether your new Mailserver works as intended and no security flaws are introduced:

* [**Relay Test**](http://www.aupads.org/test-relay.html) - checks whether your mailserver can be misused as an open mail gateway (relay)
* [**TLS Test**](https://www.checktls.com/) - checks whether your TLS configuration is complete and works as intended
* [**SMTP Test**](https://mxtoolbox.com/diagnostic.aspx) - A general mailserver diagnostic tool

# Issues
This Docker image is mature and replaced my own mailserver in production. However, several issues are still unresolved:

* [#3](https://github.com/technicalguru/docker-mailserver-postfix/issues/3) - SPF support is missing

# Contribution
Report a bug, request an enhancement or pull request at the [GitHub Issue Tracker](https://github.com/technicalguru/docker-mailserver-postfix/issues). Make sure you have checked out the [Contribution Guideline](CONTRIBUTING.md)

Thanks for their contribution to this image go to:

* [@jeroenrnl](https://github.com/jeroenrnl)

