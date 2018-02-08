#! /bin/sh

# Start cron
echo "*/5 * * * * /etc/sown/configure_scripts/available/credentials" >/etc/crontabs/root
/etc/init.d/cron enable
/etc/init.d/cron start