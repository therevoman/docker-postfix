# docker-postfix ![Docker image](https://github.com/bokysan/docker-postfix/workflows/Docker%20image/badge.svg)
Simple postfix relay host for your Docker containers. Based on Alpine Linux.


## Project update

**Notice, that while this commits are old, there project is not dead.** It's simply considered feature complete. You will find the latest version of the code on Dockerhub (https://hub.docker.com/r/boky/postfix). If you do have any suggestions, feel free to clone and post a merge.

## Description

This image allows you to run POSTFIX internally inside your docker cloud/swarm installation to centralise outgoing email sending. The embedded postfix enables you to either _send messages directly_ or _relay them to your company's main server_.

This is a _server side_ POSTFIX image, geared towards emails that need to be sent from your applications. That's why this postfix configuration does not support username / password login or similar client-side security features.

**IF YOU WANT TO SET UP AND MANAGE A POSTFIX INSTALLATION FOR END USERS, THIS IMAGE IS NOT FOR YOU.** If you need it to manage your application's outgoing queue, read on.

## TL;DR

To run the container, do the following:
```
docker run --rm --name postfix -e "ALLOWED_SENDER_DOMAINS=example.com" -p 1587:587 boky/postfix
```

You can now send emails by using `localhost:1587` as your SMTP server address. Of course, if
you haven't configured your `example.com` domain to allow sending from this IP (see
[openspf](http://www.openspf.org/)), your emails will most likely be regarded as spam.

All standard caveats of configuring the SMTP server apply:
- **MAKE SURE YOUR OUTGOING PORT 25 IS NOT BLOCKED.** 
  - Most ISPs block outgoing connections to port 25 and several companies (e.g. [NoIP](https://www.noip.com/blog/2013/03/26/my-isp-blocks-smtp-port-25-can-i-still-host-a-mail-server/), [Dynu](https://www.dynu.com/en-US/Blog/Article?Article=How-to-host-email-server-if-ISP-blocks-port-25) offer workarounds). 
  - Hosting centers also tend to block port 25, which can be unblocked per requirst (e.g. for AWS either [fill out a form](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-port-25-throttle/) or forward mail to their [SES](https://aws.amazon.com/ses/) service, which is free for low volumes)
- You'll most likely need to at least [set up SPF records](https://en.wikipedia.org/wiki/Sender_Policy_Framework) or [DKIM](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail)
- If using DKIM (below), make sure to add DKIM keys to your domain's DNS entries
- You'll most likely need to set up (PTR)[https://en.wikipedia.org/wiki/Reverse_DNS_lookup] records to prevent your mails going to spam

If you don't know what any of the above means, get some help. Google is your friend. It's also worth noting that as a consequence it's pretty difficult to host a SMTP server on a dynamic IP address.


**Please note that the image uses the submission (587) port by default**. Port 25 is not 
exposed on purpose, as it's regularly blocked by ISP or already occupied by other services.



## Configuration options

The following configuration options are available:
```
ENV vars
$HOSTNAME = Postfix myhostname
$RELAYHOST = Host that relays your msgs
$RELAYHOST_USERNAME = An (optional) username for the relay server
$RELAYHOST_PASSWORD = An (optional) login password for the relay server
$MYNETWORKS = allow domains from per Network ( default 127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 )
$ALLOWED_SENDER_DOMAINS = domains sender domains
$ALLOW_EMPTY_SENDER_DOMAINS = if value is set (i.e: "true"), $ALLOWED_SENDER_DOMAINS can be unset
$MASQUERADED_DOMAINS = domains where you want to masquerade internal hosts

```
### `HOSTNAME`

You may configure a specific hostname that the SMTP server will use to identify itself. If you don't do it,
the default Docker host name will be used. A lot of times, this will be just the container id (e.g. `f73792d540a5`)
which may make it difficult to track your emails in the log files. If you care about tracking at all,
I suggest you set this variable, e.g.:
```
docker run --rm --name postfix -e HOSTNAME=postfix-docker -p 1587:587 boky/postfix
```

### `RELAYHOST`, `RELAYHOST_USERNAME` and `RELAYHOST_PASSWORD`

Postfix will try to deliver emails directly to the target server. If you are behind a firewall, or inside a corporation
you will most likely have a dedicated outgoing mail server. By setting this option, you will instruct postfix to relay
(hence the name) all incoming emails to the target server for actual delivery.

Example:
```
docker run --rm --name postfix -e RELAYHOST=192.168.115.215 -p 1587:587 boky/postfix
```

You may optionally specifiy a relay port, e.g.:
```
docker run --rm --name postfix -e RELAYHOST=192.168.115.215:587 -p 1587:587 boky/postfix
```

Or an IPv6 address, e.g.:
```
docker run --rm --name postfix -e 'RELAYHOST=[2001:db8::1]:587' -p 1587:587 boky/postfix
```

If your end server requires you to authenticate with username/password, add them also:
```
docker run --rm --name postfix -e RELAYHOST=mail.google.com -e RELAYHOST_USERNAME=hello@gmail.com -e RELAYHOST_PASSWORD=world -p 1587:587 boky/postfix
```

### `RELAYHOST_TLS_LEVEL`

Define relay host TLS connection level. See http://www.postfix.org/postconf.5.html#smtp_tls_security_level for details. By default, the permissive level ("may") is used, which basically means "use TLS if available" and should be a sane default in most cases.

This level defines how the postfix will connect to your upstream server.

### `MESSAGE_SIZE_LIMIT`

Define the maximum size of the message, in bytes. 
See more in [Postfix documentation](http://www.postfix.org/postconf.5.html#message_size_limit). 

By default, this limit is set to 0 (zero), which means unlimited. Why would you want to set this? Well, this is especially useful in relation
with `RELAYHOST` setting. If your relay host has a message limit (and usually it does), set it also here. This will help you "fail fast" --
your message will be rejected at the time of sending instead having it stuck in the outbound queue indefenetly.


### `MYNETWORKS`

This implementation is meant for private installations -- so that when you configure your services using _docker compose_
you can just plug it in. Precisely because of this reason and the prevent any issues with this postfix being inadvertently
exposed on the internet and then used for sending spam, the *default networks are reserved for private IPv4 IPs only*.

Most likely you won't need to change this. However, if you need to support IPv6 or strenghten the access further, you can
override this setting.

Example:
```
docker run --rm --name postfix -e "MYNETWORKS=10.1.2.0/24" -p 1587:587 boky/postfix
```

### `ALLOWED_SENDER_DOMAINS`

Due to in-built spam protection in [Postfix](http://www.postfix.org/postconf.5.html#smtpd_relay_restrictions) you will need to specify
sender domains -- the domains you are using to send your emails from, otherwise Postfix will refuse to start.

Example:
```
docker run --rm --name postfix -e "ALLOWED_SENDER_DOMAINS=example.com example.org" -p 1587:587 boky/postfix
```

If you want to set the restrictions on the recipient and not on the sender (anyone can send mails but just to a single domain for instance), set `ALLOW_EMPTY_SENDER_DOMAINS` to a non-empty value (e.g. `true`) and `ALLOWED_SENDER_DOMAINS` to an empty string. Then extend this image through custom scripts to configure Postfix further.

### `INBOUND_DEBUGGING`

Enable additional debugging for any connection comming from `MYNETWORKS`. Set to a non-empty string (usually "1" or "yes") to
enable debugging.


### `MASQUERADED_DOMAINS`

If you don't want outbound mails to expose hostnames, you can use this variable to enable Postfix's [address masquerading](http://www.postfix.org/ADDRESS_REWRITING_README.html#masquerade). This can be used to do things like rewrite `lorem@ipsum.example.com` to `lorem@example.com`.

Example:
```
docker run --rm --name postfix -e "ALLOWED_SENDER_DOMAINS=example.com example.org" -e "MASQUERADED_DOMAINS=example.com" -p 1587:587 boky/postfix
```

### `SMTP_HEADER_CHECKS`

This image allows you to execute Postfix [header checks](http://www.postfix.org/header_checks.5.html). Header checks allow you to execute a certain
action when a certain MIME header is found. For example, header checks can be used prevent attaching executable files to emails.

Header checks work by comparing each message header line to a pre-configured list of patterns. When a match is found the corresponding action is 
executed. The default patterns that come with this image can be found in the `smtp_header_checks` file. Feel free to override this file in any derived
images or, alternately, provide your own in another directory.

Set `SMTP_HEADER_CHECKS` to type and location of the file to enable this feature. The sample file is uploaded into `/etc/postfix/smtp_header_checks` 
in the image. As a convenience, setting `SMTP_HEADER_CHECKS=1` will set this to `regexp:/etc/postfix/smtp_header_checks`.

Example:
```
docker run --rm --name postfix -e "SMTP_HEADER_CHECKS="regexp:/etc/postfix/smtp_header_checks" -e "ALLOWED_SENDER_DOMAINS=example.com example.org" -p 1587:587 boky/postfix
```

## `DKIM`

**This image is equiped with support for DKIM.** If you want to use DKIM you will need to generate DKIM keys yourself. 
You'll need to create a  folder for every domain you want to send through Postfix and generate they key(s) with the following command, e.g.

```
mkdir -p /host/keys; cd /host/keys

for DOMAIN in example.com example.org; do
    # Generate a key with selector "mail"
    opendkim-genkey -b 2048 -h rsa-sha256 -r -v --subdomains -s mail -d $DOMAIN
    # Fixes https://github.com/linode/docs/pull/620
    sed -i 's/h=rsa-sha256/h=sha256/' mail.txt
    # Move to proper file
    mv mail.private $DOMAIN.private
    mv mail.txt $DOMAIN.txt
done
...
```

`opendkim-genkey` is usually in your favourite distribution provided by installing `opendkim-tools` or `opendkim-utils`.

Add the created `<domain>.txt` files to your DNS records. Afterwards, just mount `/etc/opendkim/keys` into your image and DKIM 
will be used automatically, e.g.:
```
docker run --rm --name postfix -e "ALLOWED_SENDER_DOMAINS=example.com example.org" -v /host/keys:/etc/opendkim/keys -p 1587:587 boky/postfix
```

## Extending the image

If you need to add custom configuration to postfix or have it do something outside of the scope of this configuration, simply
add your scripts to `/docker-init.db/`: All files with the `.sh` extension will be executed automatically at the end of the
startup script.

E.g.: create a custom `Dockerfile` like this:
```
FROM boky/postfix
LABEL maintainer="Jack Sparrow <jack.sparrow@theblackpearl.example.com>"
ADD Dockerfiles/additional-config.sh /docker-init.db/
```

Build it with docker and your script will be automatically executed before Postfix starts.

Or -- alternately -- bind this folder in your docker config and put your scripts there. Useful if you need to add additional config
to your postfix server or override configs created by the script.

For example, your script could contain something like this:
```
#!/bin/sh
postconf -e "address_verify_negative_cache=yes"
```


## Security

Postfix will run the master proces as `root`, because that's how it's designed. Subprocesses will run under the `postfix` account
which will use `UID:GID` of `100:101`. `opendkim` will run under account `102:103`.
