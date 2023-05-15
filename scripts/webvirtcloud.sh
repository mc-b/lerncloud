#!/bin/bash
#
#   Install WebVirtcloud
#

sudo apt-get -y install git virtualenv python3-virtualenv python3-dev python3-lxml libvirt-dev zlib1g-dev libxslt1-dev nginx supervisor libsasl2-modules gcc pkg-config python3-guestfs libsasl2-dev libldap2-dev libssl-dev

git clone https://github.com/retspen/webvirtcloud
cd webvirtcloud
cp webvirtcloud/settings.py.template webvirtcloud/settings.py

cat <<EOF | python3 >secret_key
import random, string
haystack = string.ascii_letters + string.digits
print(''.join([random.SystemRandom().choice(haystack) for _ in range(50)]))
EOF
sed -i "s/SECRET_KEY = \"\"/SECRET_KEY = \'$(cat secret_key)\'/g" webvirtcloud/settings.py
rm secret_key

sudo cp conf/supervisor/webvirtcloud.conf /etc/supervisor/conf.d
sudo cp conf/nginx/webvirtcloud.conf /etc/nginx/conf.d
cd ..
sudo mv webvirtcloud /srv
sudo chown -R ubuntu:ubuntu /srv/webvirtcloud

cd /srv/webvirtcloud
virtualenv -p python3 venv
source venv/bin/activate
pip install -r conf/requirements.txt
python3 manage.py migrate
python3 manage.py collectstatic --noinput
sudo chown -R www-data:www-data /srv/webvirtcloud
sudo rm -f /etc/nginx/sites-enabled/default
sudo chown -R www-data:www-data /srv/webvirtcloud

sudo service nginx restart
sudo service supervisor restart

