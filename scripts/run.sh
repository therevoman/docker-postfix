#!/usr/bin/env bash
set -e

. /common.sh
. /common-run.sh

announce_startup                    # Print startup banner
setup_timezone                      # Check if we need to configure the container timezone
rsyslog_log_format                  # Setup rsyslog output format
setup_conf                          # Copy over files from /etc/postfix.template to /etc/postfix, if the user mounted the folder manually
reown_folders                       # Make and reown /var/spool/postfix/ folders
#postfix_upgrade_conf                # Upgrade old coniguration, replace "hash:" and "btree:" databases to "lmdb:"
postfix_disable_utf8                # Disable SMTPUTF8, because libraries (ICU) are missing in alpine
postfix_create_aliases              # Update aliases database. It's not used, but postfix complains if the .db file is missing
postfix_disable_local_mail_delivery # Disable local mail delivery
postfix_disable_domain_relays       # Don't relay for any domains
postfix_increase_header_size_limit  # Increase the allowed header size, the default (102400) is quite smallish
postfix_restrict_message_size       # Restrict the size of messages (or set them to unlimited)
postfix_reject_invalid_helos        # Reject invalid HELOs
postfix_set_hostname                # Set up host name
postfix_set_relay_tls_level         # Set TLS level security for relays
postfix_setup_xoauth2_pre_setup     # (Pre) Setup XOAUTH2 authentication
postfix_setup_relayhost             # Setup a relay host, if defined
postfix_setup_xoauth2_post_setup    # (Post) Setup XOAUTH2 autentication
postfix_setup_networks              # Set MYNETWORKS
postfix_setup_debugging             # Enable debugging, if defined
postfix_setup_sender_domains        # Configure allowed sender domains
postfix_setup_masquarading          # Setup masquaraded domains
postfix_setup_header_checks         # Enable SMTP header checks, if defined
postfix_setup_dkim                  # Configure DKIM, if enabled
postfix_custom_commands             # Apply custom postfix settings
opendkim_custom_commands            # Apply custom OpenDKIM settings
postfix_open_submission_port        # Enable the submission port
execute_post_init_scripts           # Execute any scripts found in /docker-init.db/
unset_sensible_variables            # Remove environment variables that contains sensible values (secrets) that are read from conf files

notice "Starting: ${emphasis}rsyslog${reset}, ${emphasis}postfix${reset}$DKIM_ENABLED"
exec supervisord -c /etc/supervisord.conf
