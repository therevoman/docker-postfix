#!/bin/sh
postconf -e "relayhost = email-smtp.us-east-1.amazonaws.com:587"
postconf -e "smtp_sasl_auth_enable = yes"
postconf -e "smtp_sasl_security_options = noanonymous"
postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
postconf -e "smtp_use_tls = yes"
postconf -e "smtp_tls_security_level = encrypt"
postconf -e "smtp_tls_note_starttls_offer = yes"
