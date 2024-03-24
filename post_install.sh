#!/bin/sh

PAPERLESS_VERSION=2.6.3

sysrc -f /etc/rc.conf redis_enable="YES"
sysrc -f /etc/rc.conf incrond_enable="YES"

service redis restart
service incron restart

mkdir -p /opt
cd /opt

curl -L -O https://github.com/paperless-ngx/paperless-ngx/releases/download/v${PAPERLESS_VERSION}/paperless-ngx-v${PAPERLESS_VERSION}.tar.xz
tar zvxf paperless-ngx-v${PAPERLESS_VERSION}.tar.xz
mv paperless-ngx /opt/paperless

pw group add -n paperless -g 1004
pw group add -n familie -g 2003
pw user add -n paperless -u 1004 -g 1004 -c 'Paperless' -d /opt/paperless -m -s /bin/sh
pw usermod paperless -G familie
chown -R paperless:paperless /opt/paperless

cp -v /opt/paperless/paperless.conf /opt/paperless/paperless.conf.orig

sed -i "" -e 's/#PAPERLESS_CONSUMER_POLLING/PAPERLESS_CONSUMER_POLLING/' /opt/paperless/paperless.conf
sed -i "" -e 's/#PAPERLESS_DATA_DIR/PAPERLESS_DATA_DIR/' /opt/paperless/paperless.conf
sed -i "" -e  "/PAPERLESS_DATA_DIR/ a\\
PAPERLESS_NLTK_DIR=../data/nltk\
" /opt/paperless/paperless.conf
sed -i "" -e 's/#PAPERLESS_MEDIA_ROOT/PAPERLESS_MEDIA_ROOT/' /opt/paperless/paperless.conf
sed -i "" -e 's/#PAPERLESS_CONSUMPTION_DIR/PAPERLESS_CONSUMPTION_DIR/' /opt/paperless/paperless.conf
sed -i "" -e 's/#PAPERLESS_REDIS/PAPERLESS_REDIS/' /opt/paperless/paperless.conf
sed -i "" -e  "/PAPERLESS_REDIS/ a\\
PAPERLESS_DBENGINE=sqlite\
" /opt/paperless/paperless.conf


sed -i "" -e '/PDF/s/rights="none"/rights="read|write"/' /usr/local/etc/ImageMagick-7/policy.xml

su paperless -c /tmp/paperless_install
sysrc -f /etc/rc.conf paperlessconsumer_enable="YES"
sysrc -f /etc/rc.conf paperlesswebserver_enable="YES"
sysrc -f /etc/rc.conf paperlessscheduler_enable="YES"
sysrc -f /etc/rc.conf paperlesstaskqueue_enable="YES"

service paperlesswebserver start
service paperlessconsumer start
service paperlessscheduler start
service paperlesstaskqueue start

echo "The default username and password for this install is admin for both" >> /root/PLUGIN_INFO
