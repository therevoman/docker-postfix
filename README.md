# docker-postfix ![Docker image](https://github.com/bokysan/docker-postfix/workflows/Docker%20image/badge.svg) [![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fbokysan%2Fdocker-postfix.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fbokysan%2Fdocker-postfix?ref=badge_shield)

Simple postfix relay host ("postfix null client") for your Docker containers. Based on Alpine Linux.

## Table of contents

* [Table of contents](#table-of-contents)
* [Description](#description)
* [TL;DR](#tldr)
* [Configuration options](#configuration-options)
  * [General options](#general-options)
    * [Inbound debugging](#inbound-debugging)
    * [ALLOWED_SENDER_DOMAINS and ALLOW_EMPTY_SENDER_DOMAINS](#allowed_sender_domains-and-allow_empty_sender_domains)
    * [Log format](#log-format)
  * [Postfix-specific options](#postfix-specific-options)
    * [RELAYHOST, RELAYHOST_USERNAME and RELAYHOST_PASSWORD](#relayhost-relayhost_username-and-relayhost_password)
    * [RELAYHOST_TLS_LEVEL](#relayhost_tls_level)
    * [MASQUERADED_DOMAINS](#masqueraded_domains)
    * [SMTP_HEADER_CHECKS](#smtp_header_checks)
    * [POSTFIX_hostname](#postfix_hostname)
    * [POSTFIX_mynetworks](#postfix_mynetworks)
    * [POSTFIX_message_size_limit](#postfix_message_size_limit)
    * [Overriding specific postfix settings](#overriding-specific-postfix-settings)
  * [DKIM / DomainKeys](#dkim--domainkeys)
    * [Supplying your own DKIM keys](#supplying-your-own-dkim-keys)
    * [Auto-generating the DKIM selectors through the image](#auto-generating-the-dkim-selectors-through-the-image)
    * [Changing the DKIM selector](#changing-the-dkim-selector)
    * [Overriding specific OpenDKIM settings](#overriding-specific-opendkim-settings)
    * [Verifying your DKIM setup](#verifying-your-dkim-setup)
* [Extending the image](#extending-the-image)
  * [Using custom init scripts](#using-custom-init-scripts)
* [Security](#security)
* [Quick how-tos](#quick-how-tos)
  * [Relaying messages through your Gmail account](#relaying-messages-through-your-gmail-account)
  * [Relaying messages through Google Apps account](#relaying-messages-through-google-apps-account)
  * [Sending messages directly](#sending-messages-directly)
* [Similar projects](#similar-projects)
* [License check](#license-check)

## Description

This image allows you to run POSTFIX internally inside your docker cloud/swarm installation to centralise outgoing email
sending. The embedded postfix enables you to either _send messages directly_ or _relay them to your company's main
server_.

This is a _server side_ POSTFIX image, geared towards emails that need to be sent from your applications. That's why
this postfix configuration does not support username / password login or similar client-side security features.

**IF YOU WANT TO SET UP AND MANAGE A POSTFIX INSTALLATION FOR END USERS, THIS IMAGE IS NOT FOR YOU.** If you need it to
manage your application's outgoing queue, read on.

## TL;DR

To run the container, do the following:

```shell script
docker run --rm --name postfix -e "ALLOWED_SENDER_DOMAINS=example.com" -p 1587:587 boky/postfix
```

You can now send emails by using `localhost:1587` as your SMTP server address. Of course, if
you haven't configured your `example.com` domain to allow sending from this IP (see
[openspf](http://www.openspf.org/)), your emails will most likely be regarded as spam.

All standard caveats of configuring the SMTP server apply:

- **MAKE SURE YOUR OUTGOING PORT 25 IS NOT BLOCKED.**
  - Most ISPs block outgoing connections to port 25 and several companies (e.g. [NoIP](https://www.noip.com/blog/2013/03/26/my-isp-blocks-smtp-port-25-can-i-still-host-a-mail-server/), [Dynu](https://www.dynu.com/en-US/Blog/Article?Article=How-to-host-email-server-if-ISP-blocks-port-25) offer workarounds).
  - Hosting centers also tend to block port 25, which can be unblocked per request (e.g. for AWS either [fill out a form](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-port-25-throttle/) or forward mail to their [SES](https://aws.amazon.com/ses/) service, which is free for low volumes)
- You'll most likely need to at least [set up SPF records](https://en.wikipedia.org/wiki/Sender_Policy_Framework) or [DKIM](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail)
- If using DKIM (below), make sure to add DKIM keys to your domain's DNS entries
- You'll most likely need to set up [PTR](https://en.wikipedia.org/wiki/Reverse_DNS_lookup) records to prevent your mails going to spam

If you don't know what any of the above means, get some help. Google is your friend. It's also worth noting that as a consequence it's pretty difficult to host a SMTP server on a dynamic IP address.

**Please note that the image uses the submission (587) port by default**. Port 25 is not
exposed on purpose, as it's regularly blocked by ISP or already occupied by other services.

## Configuration options

The following configuration options are available

### General options

* `TZ` = The timezone for the image
* `FORCE_COLOR` = Set to `1` to force color output (otherwise auto-detected)
* `INBOUND_DEBUGGING` = Set to `1` to enable detailed debugging in the logs
* `ALLOWED_SENDER_DOMAINS` = domains which are allowed to send email via this server
* `ALLOW_EMPTY_SENDER_DOMAINS` = if value is set (i.e: `true`), `ALLOWED_SENDER_DOMAINS` can be unset
* `LOG_FORMAT` = Set your log format (JSON or plain)

#### Inbound debugging

Enable additional debugging for any connection coming from `POSTFIX_mynetworks`. Set to a non-empty string (usually `1`
or  `yes`) to enable debugging.

#### `ALLOWED_SENDER_DOMAINS` and `ALLOW_EMPTY_SENDER_DOMAINS`

Due to in-built spam protection in [Postfix](http://www.postfix.org/postconf.5.html#smtpd_relay_restrictions) you will
need to specify sender domains -- the domains you are using to send your emails from, otherwise Postfix will refuse to
start.

Example:

```shell script
docker run --rm --name postfix -e "ALLOWED_SENDER_DOMAINS=example.com example.org" -p 1587:587 boky/postfix
```

If you want to set the restrictions on the recipient and not on the sender (anyone can send mails but just to a single domain for instance),
set `ALLOW_EMPTY_SENDER_DOMAINS` to a non-empty value (e.g. `true`) and `ALLOWED_SENDER_DOMAINS` to an empty string. Then extend this image through custom scripts to configure Postfix further.

#### Log format

The image will by default output logs in human-readable (`plain`) format. If you are deploying the image to Kubernetes,
it might be worth chaging the output format to `json` as it's more easily parsable by tools such as
[Prometheus](https://prometheus.io/).

To change the log format, set the (unsurprisingly named) variable `LOG_FORMAT=json`.

### Postfix-specific options

- `RELAYHOST` = Host that relays your messages
- `RELAYHOST_USERNAME` = An (optional) username for the relay server
- `RELAYHOST_PASSWORD` = An (optional) login password for the relay server
- `RELAYHOST_TLS_LEVEL` = Relay host TLS connection leve
- `POSTFIX_message_size_limit` = The maximum size of the messsage, in bytes, by default it's unlimited
- `POSTFIX_mynetworks` = Allow sending mails only from specific networks ( default `127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16` )
- `POSTFIX_myhostname` = Set the name of this postfix server
- `MASQUERADED_DOMAINS` = domains where you want to masquerade internal hosts
- `SMTP_HEADER_CHECKS`= Set to `1` to enable header checks of to a location
   of the file for header checks
- `POSTFIX_hostname` = Set tha name of this postfix server
- `POSTFIX_mynetworks` = Allow sending mails only from specific networks ( default `127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16` )
- `POSTFIX_message_size_limit` = The maximum size of the messsage, in bytes, by default it's unlimited
- `POSTFIX_<any_postfix_setting>` = provide any additional postfix setting

### DKIM-specific options

- `DKIM_SELECTOR` = Override the default DKIM selector (by default "mail").
- `DKIM_AUTOGENERATE` = Set to non-empty value (e.g. `true` or `1`) to have
  the server auto-generate domain keys.
- `OPENDKIM_<any_dkim_setting>` = Provide any additonal OpenDKIM setting.

### `POSTFIX_myhostname`

You may configure a specific hostname that the SMTP server will use to identify itself. If you don't do it,
the default Docker host name will be used. A lot of times, this will be just the container id (e.g. `f73792d540a5`)
which may make it difficult to track your emails in the log files. If you care about tracking at all,
I suggest you set this variable, e.g.:

```sh
docker run --rm --name postfix -e POSTFIX_myhostname=postfix-docker -p 1587:587 boky/postfix
```

### `RELAYHOST`, `RELAYHOST_USERNAME` and `RELAYHOST_PASSWORD`

Postfix will try to deliver emails directly to the target server. If you are behind a firewall, or inside a corporation
you will most likely have a dedicated outgoing mail server. By setting this option, you will instruct postfix to relay
(hence the name) all incoming emails to the target server for actual delivery.

Example:

```shell script
docker run --rm --name postfix -e RELAYHOST=192.168.115.215 -p 1587:587 boky/postfix
```

You may optionally specifiy a relay port, e.g.:

```shell script
docker run --rm --name postfix -e RELAYHOST=192.168.115.215:587 -p 1587:587 boky/postfix
```

Or an IPv6 address, e.g.:

```shell script
docker run --rm --name postfix -e 'RELAYHOST=[2001:db8::1]:587' -p 1587:587 boky/postfix
```

If your end server requires you to authenticate with username/password, add them also:

```shell script
docker run --rm --name postfix -e RELAYHOST=mail.google.com -e RELAYHOST_USERNAME=hello@gmail.com -e RELAYHOST_PASSWORD=world -p 1587:587 boky/postfix
```

#### `RELAYHOST_TLS_LEVEL`

Define relay host TLS connection level. See [smtp_tls_security_level](http://www.postfix.org/postconf.5.html#smtp_tls_security_level) for details. By default, the permissive level ("may") is used, which basically means "use TLS if available" and should be a sane default in most cases.

This level defines how the postfix will connect to your upstream server.

#### `MASQUERADED_DOMAINS`

If you don't want outbound mails to expose hostnames, you can use this variable to enable Postfix's
[address masquerading](http://www.postfix.org/ADDRESS_REWRITING_README.html#masquerade). This can be used to do things
like rewrite `lorem@ipsum.example.com` to `lorem@example.com`.

Example:

```shell script
docker run --rm --name postfix -e "ALLOWED_SENDER_DOMAINS=example.com example.org" -e "MASQUERADED_DOMAINS=example.com" -p 1587:587 boky/postfix
```

#### `SMTP_HEADER_CHECKS`

This image allows you to execute Postfix [header checks](http://www.postfix.org/header_checks.5.html). Header checks
allow you to execute a certain action when a certain MIME header is found. For example, header checks can be used
prevent attaching executable files to emails.

Header checks work by comparing each message header line to a pre-configured list of patterns. When a match is found the
corresponding action is executed. The default patterns that come with this image can be found in the `smtp_header_checks`
file. Feel free to override this file in any derived images or, alternately, provide your own in another directory.

Set `SMTP_HEADER_CHECKS` to type and location of the file to enable this feature. The sample file is uploaded into
`/etc/postfix/smtp_header_checks` in the image. As a convenience, setting `SMTP_HEADER_CHECKS=1` will set this to
`regexp:/etc/postfix/smtp_header_checks`.

Example:

```shell script
docker run --rm --name postfix -e "SMTP_HEADER_CHECKS="regexp:/etc/postfix/smtp_header_checks" -e "ALLOWED_SENDER_DOMAINS=example.com example.org" -p 1587:587 boky/postfix
```

#### `POSTFIX_hostname`

You may configure a specific hostname that the SMTP server will use to identify itself. If you don't do it,
the default Docker host name will be used. A lot of times, this will be just the container id (e.g. `f73792d540a5`)
which may make it difficult to track your emails in the log files. If you care about tracking at all,
I suggest you set this variable, e.g.:

```shell script
docker run --rm --name postfix -e "POSTFIX_hostname=postfix-docker" -p 1587:587 boky/postfix
```

#### `POSTFIX_mynetworks`

This implementation is meant for private installations -- so that when you configure your services using _docker compose_
you can just plug it in. Precisely because of this reason and the prevent any issues with this postfix being inadvertently
exposed on the internet and then used for sending spam, the *default networks are reserved for private IPv4 IPs only*.

Most likely you won't need to change this. However, if you need to support IPv6 or strenghten the access further, you
can override this setting.

Example:

```shell script
docker run --rm --name postfix -e "POSTFIX_mynetworks=10.1.2.0/24" -p 1587:587 boky/postfix
```

#### `POSTFIX_message_size_limit`

Define the maximum size of the message, in bytes.
See more in [Postfix documentation](http://www.postfix.org/postconf.5.html#message_size_limit).

By default, this limit is set to 0 (zero), which means unlimited. Why would you want to set this? Well, this is
especially useful in relation with `RELAYHOST` setting. If your relay host has a message limit (and usually it does),
set it also here. This will help you "fail fast" -- your message will be rejected at the time of sending instead having
it stuck in the outbound queue indefinitely.

#### Overriding specific postfix settings

Any Postfix [configuration option](http://www.postfix.org/postconf.5.html) can be overriden using `POSTFIX_<name>`
environment variables, e.g. `POSTFIX_allow_mail_to_commands=alias,forward,include`. Specifying no content (empty
variable) will remove that variable from postfix config.

### DKIM / DomainKeys

**This image is equipped with support for DKIM.** If you want to use DKIM you will need to generate DKIM keys. These can
be either generated automatically, or you can supply them yourself.

The DKIM supports the following options:

* `DKIM_SELECTOR` = Override the default DKIM selector (by default "mail").
* `DKIM_AUTOGENERATE` = Set to non-empty value (e.g. `true` or `1`) to have
  the server auto-generate domain keys.
* `OPENDKIM_<any_dkim_setting>` = Provide any additional OpenDKIM setting.

#### Supplying your own DKIM keys

If you want to use your own DKIM keys, you'll need to create a folder for every domain you want to send through. You
will need to generate they key(s) with the `opendkim-genkey` command, e.g.

```shell script
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

Add the created `<domain>.txt` files to your DNS records. Afterwards, just mount `/etc/opendkim/keys` into your image
and DKIM will be used automatically, e.g.:

```shell script
docker run --rm --name postfix -e "ALLOWED_SENDER_DOMAINS=example.com example.org" -v /host/keys:/etc/opendkim/keys -p 1587:587 boky/postfix
```

#### Auto-generating the DKIM selectors through the image

If you set the environment variable `DKIM_AUTOGENERATE` to a non-empty value (e.g. `true` or `1`) the image will
automatically generate the keys.

**Be careful when using this option**. If you don't bind `/etc/opendkim/keys` to a persistent volume, you will get new
keys every single time. You will need to take the generated public part of the key (the one in the `.txt` file) and
copy it over to your DNS server manually.

#### Changing the DKIM selector

`mail` is the *default DKIM selector* and should be sufficient for most usages. If you wish to override the selector,
set the environment variable `DKIM_SELECTOR`, e.g. `... -e DKIM_SELECTOR=postfix`. Note that the same DKIM selector will
be applied to all found domains. To override a selector for a specific domain use the syntax
`[<domain>=<selector>,...]`, e.g.:

```shell script
DKIM_SELECTOR=foo,example.org=postfix,example.com=blah
```

This means:

* use `postfix` for `example.org` domain
* use `blah` for `example.com` domain
* use `foo` if no domain matches

#### Overriding specific OpenDKIM settings

Any OpenDKIM [configuration option](http://opendkim.org/opendkim.conf.5.html) can be overriden using `OPENDKIM_<name>`
environment variables, e.g. `OPENDKIM_RequireSafeKeys=yes`. Specifying no content (empty variable) will remove that
variable from OpenDKIM config.

#### Verifying your DKIM setup

I strongly suggest using a service such as [dkimvalidator](https://dkimvalidator.com/) to make sure your keys are set up
properly and your DNS server is serving them with the correct records.

## Extending the image

### Using custom init scripts

If you need to add custom configuration to postfix or have it do something outside of the scope of this configuration,
simply add your scripts to `/docker-init.db/`: All files with the `.sh` extension will be executed automatically at the
end of the startup script.

E.g.: create a custom `Dockerfile` like this:

```shell script
FROM boky/postfix
LABEL maintainer="Jack Sparrow <jack.sparrow@theblackpearl.example.com>"
ADD Dockerfiles/additional-config.sh /docker-init.db/
```

Build it with docker, and your script will be automatically executed before Postfix starts.

Or -- alternately -- bind this folder in your docker config and put your scripts there. Useful if you need to add a
config to your postfix server or override configs created by the script.

For example, your script could contain something like this:

```shell script
#!/bin/sh
postconf -e "address_verify_negative_cache=yes"
```

## Security

Postfix will run the master proces as `root`, because that's how it's designed. Subprocesses will run under the `postfix`
account which will use `UID:GID` of `100:101`. `opendkim` will run under account `102:103`.

## Quick how-tos

### Relaying messages through your Gmail account

Please note that Gmail does not support using your password with non-OAuth2 clients, which -- technically -- postfix is.
You will need to enable [Less secure apps](https://support.google.com/accounts/answer/6010255?hl=en) in your account
and assign an "app password". You'll also need to use (only) your email as the sender address.

Your configuration would be as follows:

```shell script
RELAYHOST=smtp.gmail.com:587
RELAYHOST_USERNAME=you@gmail.com
RELAYHOST_PASSWORD=your-gmail-app-password
ALLOWED_SENDER_DOMAINS=gmail.com
```

There's no need to configure DKIM or SPF, as Gmail will add these headers automatically.

### Relaying messages through Google Apps account

Google Apps allows third-party services to use Google's SMTP servers without much hassle. If you have a static IP, you
can configure Gmail to accept your messages. You can then send email *from any address within your domain*.

You need to enable the [SMTP relay service](https://support.google.com/a/answer/2956491?hl=en):
- Go to Google [Admin /Apps / G Suite / Gmail /Advanced settings](https://admin.google.com/AdminHome?hl=en_GB#ServiceSettings/service=email&subtab=filters).
- Find the **Routing / SMTP relay service**
- Click **Add another** button that pops up when you hover over the line
- Enter the name and your server's external IP as shown in the picture below:
    - **Allowed senders:** Only registered Apps users in my domains
    - Select **Only accept mail from specified IP Addresses**
    - Click **Add IP RANGE** and add your external IP
    - Make sure **Require SMTP Authentication** is **NOT** selected
    - You *may* select **Require TLS encryption**

![Add setting SMTP relay service](GApps-SMTP-config.png)

* Go to Google [Admin /Apps / G Suite / Gmail /Advanced settings](https://admin.google.com/AdminHome?hl=en_GB#ServiceSettings/service=email&subtab=filters).
* Find the **Routing / SMTP relay service**
* Click **Add another** button that pops up when you hover over the line
* Enter the name and your server's external IP as shown in the picture below:
  * **Allowed senders:** Only registered Apps users in my domains
  * Select **Only accept mail from specified IP Addresses**
  * Click **Add IP RANGE** and add your external IP
  * Make sure **Require SMTP Authentication** is **NOT** selected
  * You *may* select **Require TLS encryption**

![Add setting SMTP relay service](GApps-SMTP-config.png)

Your configuration would be as follows:

```shell script
RELAYHOST=smtp-relay.gmail.com:587
ALLOWED_SENDER_DOMAINS=<your-domain>
```

There's no need to configure DKIM or SPF, as Gmail will add these headers automatically.

### Sending messages directly

If you're sending messages directly, you'll need to:

- need to have a fixed IP address;
- configure a reverse PTR record;
- configure SPF and/or DKIM as explained in this document;
- it's also highly advisable to have your own IP block.


Your configuration would be as follows:

```shell script
ALLOWED_SENDER_DOMAINS=<your-domain>
```

## Similar projects

There are may other project offering similar functionality. The aim of this project, however, is:

* to make it as simple as possible to run the relay, without going too much into postfix configuration details
* to make the image as small as possible (hence basing on Alpine linux)
* to make the image and the corresponding code testable

The other projects are, in completely random order:

* [wader/postfix-relay](https://github.com/wader/postfix-relay)
* [catatnight/postfix](https://github.com/catatnight/docker-postfix)
* [juanluisbaptiste/docker-postfix](https://github.com/juanluisbaptiste/docker-postfix)
* [docker-mail-relay](https://github.com/alterrebe/docker-mail-relay)

## License check

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fbokysan%2Fdocker-postfix.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Fbokysan%2Fdocker-postfix?ref=badge_large)
