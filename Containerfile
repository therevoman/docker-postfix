#FROM registry.access.redhat.com/ubi8/ubi
FROM registry.access.redhat.com/ubi9/ubi

LABEL name="therevoman/container-postfix" \
      maintainer="Nate Revo" \
      version="1.0.0" \
      release="1" \
      summary="postfix on ubi9" \
      description="This application enables a smtp relay."


#RUN true && \
#    microdnf update -y && \
#    microdnf install postfix bind-utils yum-utils -y && \
#    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
#    /usr/bin/crb enable && \
#    # requires python 3.6+
#    microdnf install pypolicyd-spf -y && \ 
#    microdnf install opendkim-tools perl-Getopt-Long -y && \
##    microdnf install opendkim -y && \
#    microdnf clean all

COPY sendmail-milter-8.16.1-10.el9.x86_64.rpm /tmp

RUN true && \
    dnf update -y && \
    dnf install postfix bind-utils yum-utils -y && \
    dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y && \
    /usr/bin/crb enable && \
    # requires python 3.6+
    dnf install supervisor rsyslog -y && \
    dnf install pypolicyd-spf -y && \ 
    dnf install opendkim-tools perl-Getopt-Long -y && \
    dnf install /tmp/sendmail-milter-8.16.1-10.el9.x86_64.rpm -y && \
    dnf install opendkim libgsasl libgsasl-devel cyrus-sasl cyrus-sasl-plain -y && \
    dnf clean all




#    microdnf install opendkim opendkim-tools perl-Getopt-Long --enablerepo=codeready-builder-for-rhel-8-x86_64-rpms -y && \
#    microdnf install --enablerepo=ubi-9-codeready-builder-rpms opendkim -y && \

#RUN \
#    dnf update -y && \
#    dnf install postfix -y && \
#    dnf install bind-utils -y && \
#    # requires python 3.6+
##    microdnf install pypolicyd-spf -y && \ 
##    dnf install --enablerepo=ubi-9-codeready-builder-rpms opendkim -y && \
##    dnf install opendkim-tools perl-Getopt-Long -y && \
#    dnf clean all

## RELAYHOST=mail.google.com RELAYHOST_USERNAME=revoman@gmail.com ALLOWED_SENDER_DOMAINS="revoweb.com" /run.sh

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
