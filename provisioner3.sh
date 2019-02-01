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

yum install -y php php-mysql php-xml php-xml-* php-gd php-tidy php-soap php-xdebug php-mbstring
# yum install -y http://ftp.altlinux.org/pub/distributions/ALTLinux/Sisyphus/x86_64/RPMS.classic//libtidy-0.99-alt11.20051026.x86_64.rpm
# yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/p/php-tidy-5.4.16-7.el7.x86_64.rpm

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/bin/composer
composer create-project silverstripe/installer /var/www/html
cp -f /var/www/html/framework/sake /usr/bin
chmod +x /usr/bin/sake

cd /var/www/html
composer require phpunit/php-invoker

chown -R vagrant:vagrant /var/log/httpd
chown -R vagrant:vagrant /var/www
chgrp vagrant /var/lib/php/session

sed -i -e 's/User apache/User vagrant/g' /etc/httpd/conf/httpd.conf
sed -i -e 's/Group apache/Group vagrant/g' /etc/httpd/conf/httpd.conf
# sed -i -e 's/AllowOverride none/AllowOverride All/g' /etc/httpd/conf/httpd.conf
# sed -i -e 's/Require all denied//g' /etc/httpd/conf/httpd.conf
sed -i -e 's/AllowOverride None/AllowOverride All/g' /etc/httpd/conf/httpd.conf
echo "IncludeOptional conf.modules.d/*.conf"|sudo tee --append /etc/httpd/conf/httpd.conf
echo "date.timezone=Europe/Rome"|sudo tee --append /etc/php.ini
echo "upload_max_filesize = 200M"|sudo tee --append /etc/php.ini
echo "post_max_size = 200M"|sudo tee --append /etc/php.ini
echo "memory_limit = 512M"|sudo tee --append /etc/php.ini

cat > /var/www/html/_ss_environment.php << EOF
<?php

//define DB settings
define('SS_DATABASE_SERVER', '127.0.0.1');
define('SS_DATABASE_CLASS','MySQLDatabase');
define('SS_DATABASE_TIMEZONE','+00:00');
define('SS_DATABASE_USERNAME', 'root');
define('SS_DATABASE_PASSWORD', '');
define('SS_DATABASE_NAME', 'vagrant');

//set the DB name - this provide backwards compatibility with 2.x and 3.0 sites
global \$database;
\$database = SS_DATABASE_NAME;

define('SS_ENVIRONMENT_TYPE', 'dev');

define('SS_DEFAULT_ADMIN_USERNAME', 'admin');
define('SS_DEFAULT_ADMIN_PASSWORD', 'password');

global \$_FILE_TO_URL_MAPPING;
\$_FILE_TO_URL_MAPPING['/var/www/html'] = 'http://localhost';
EOF

cat > /var/www/html/mysite/_config.php << EOF
<?php

global \$project;
\$project = 'mysite';

global \$databaseConfig;
GD::set_default_quality(60);
Currency::setCurrencySymbol('€');

if (!Director::isDev()) {
    // log errors and warnings
    SS_Log::add_writer(new SS_LogFileWriter('../silverstripe-errors-warnings.log'), SS_Log::WARN, '<=');
}


// Set the site locale
i18n::set_locale('it_IT');

SSViewer::set_theme('simple');
require_once("conf/ConfigureFromEnv.php");
EOF

systemctl start httpd.service
sake dev/build "flush=1"
rm -f install.php
git init
git add .
git config --global user.email "giancarlo@digitall.it"
git config --global user.name "Giancarlo"
git commit -m 'Initial commit'
// @TODO gitignore these files
echo "<?php phpinfo();" > info.php
// ln -s /etc/httpd/logs/error_log /var/www/html/error.log

