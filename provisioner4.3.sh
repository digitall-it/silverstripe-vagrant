export VM_HOSTNAME=${VM_HOSTNAME}
systemctl disable firewalld
systemctl stop firewalld

yum -y update

yum install -y mariadb-server mariadb
systemctl start mariadb
systemctl enable mariadb.service

mysql -sfu root <<_EOF_
USE mysql;
UPDATE mysql.user SET Password=PASSWORD('') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_


yum install -y httpd
systemctl enable httpd.service

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

yum install -y php70w mod_php70w php70w-cli php70w-common php70w-gd php70w-mbstring php70w-mcrypt php70w-mysqlnd php70w-xml php70w-intl php70w-opcache php70w-tidy

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/bin/composer
composer create-project silverstripe/installer /var/www/html ^4
# composer require phpunit/php-invoker

cp -f /var/www/html/vendor/silverstripe/framework/sake /usr/bin
chmod +x /usr/bin/sake

cd /var/www/html
composer require --dev phpunit/php-invoker

# chown -R vagrant:vagrant /var/log/httpd
# chown -R vagrant:vagrant /var/www
chgrp -R vagrant /var/lib/php


sed -i -e 's/User apache/User vagrant/g' /etc/httpd/conf/httpd.conf
sed -i -e 's/Group apache/Group vagrant/g' /etc/httpd/conf/httpd.conf
sed -i -e 's/AllowOverride None/AllowOverride All/g' /etc/httpd/conf/httpd.conf
echo "IncludeOptional conf.modules.d/*.conf"|sudo tee --append /etc/httpd/conf/httpd.conf

cat << 'EOF' >> /etc/php.ini

date.timezone=Europe/Rome
upload_max_filesize = 200M
post_max_size = 200M
memory_limit = 512M
EOF

echo "<?php phpinfo();" > info.php

# ln -s /etc/httpd/logs/error_log /var/www/html/error.log

chown -R vagrant:vagrant /var/log/httpd

systemctl start httpd.service

cat << 'EOF' > /var/www/html/.env
SS_ENVIRONMENT_TYPE="dev"
SS_DEFAULT_ADMIN_USERNAME="admin"
SS_DEFAULT_ADMIN_PASSWORD="password"
SS_BASE_URL="//$VM_HOSTNAME"
SS_DATABASE_CLASS="MySQLPDODatabase"
SS_DATABASE_NAME="SS_mysite"
SS_DATABASE_PASSWORD=""
SS_DATABASE_SERVER="localhost"
SS_DATABASE_USERNAME="root"
EOF

cat << 'EOF' >> /var/www/html/app/_config/theme.yml
SilverStripe\i18n\i18n:
  default_locale: 'it_IT'
EOF

cd /var/www/html
sake dev/build "flush=1"
# rm -f /var/www/html/install.php

git init
git add .
git config --global user.email "giancarlo@digitall.it"
git config --global user.name "Giancarlo"
git commit -m 'Initial commit'
