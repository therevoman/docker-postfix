FROM registry.access.redhat.com/ubi9/ubi-minimal

LABEL name="therevoman/container-postfix" \
      maintainer="Nate Revo" \
      version="1.0.0" \
      release="1" \
      summary="postfix on ubi9" \
      description="This application enables a smtp relay."


RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    microdnf update -y && \
    microdnf install postfix mailx -y && \
    microdnf install bind-utils -y && \
    microdnf install pypolicyd-spf -y && \
    microdnf install opendkim opendkim-tools perl-Getopt-Long -y && \
    microdnf clean all

#RUN dnf update -y && \
#    dnf install postfix mailx && \
#    dnf clean all

# Set up configuration
COPY       /configs/supervisord.conf     /etc/supervisord.conf
COPY       /configs/rsyslog*.conf        /etc/
COPY       /configs/opendkim.conf        /etc/opendkim/opendkim.conf
COPY       /configs/smtp_header_checks   /etc/postfix/smtp_header_checks
COPY       /scripts/*.sh                 /

RUN        chmod +x /run.sh /opendkim.sh

# Set up volumes
VOLUME     [ "/var/spool/postfix", "/etc/postfix", "/etc/opendkim/keys" ]

# Run supervisord
USER       root
WORKDIR    /tmp

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD printf "EHLO healthcheck\n" | nc 127.0.0.1 587 | grep -qE "^220.*ESMTP Postfix"

EXPOSE     587
CMD        [ "/bin/sh", "-c", "/run.sh" ]
