#!/usr/bin/env bash

readonly stage_site=stage.negombo.it
readonly stage_dir=stage.negombo.it

readonly prod_site=negombo.it
readonly prod_dir=httpdocs

# Do not edit past this point

readonly version=1.3

echo Migrator v$version

if [ "$#" -ne 2 ]; then
	echo "Illegal number of parameters"
	exit 1
fi

opt_from="$1"
opt_to="$2"

function detect_stage_credentials {
echo Detecting stage site credentials...

if ssh $stage_site "stat \"$stage_dir/_ss_environment.php\"" \> /dev/null 2\>\&1
then

readonly stage_sql_user=`ssh $stage_site "php -r 'require \"$stage_dir/_ss_environment.php\";echo SS_DATABASE_USERNAME;'"`
readonly stage_sql_password=`ssh $stage_site "php -r 'require \"$stage_dir/_ss_environment.php\";echo SS_DATABASE_PASSWORD;'"`
readonly stage_sql_db=`ssh $stage_site "php -r 'require \"$stage_dir/_ss_environment.php\";echo SS_DATABASE_NAME;'"`

echo "Silverstripe 3.x installation detected on stage site"

else

echo "Silverstripe 3.x installation not detected on stage site"
exit 1

fi
}
function detect_prod_credentials {
echo Detecting production site credentials...


if ssh $prod_site "stat \"$prod_dir/_ss_environment.php\"" \> /dev/null 2\>\&1
then

readonly prod_sql_user=`ssh $prod_site "php -r 'require \"$prod_dir/_ss_environment.php\";echo SS_DATABASE_USERNAME;'"`
readonly prod_sql_password=`ssh $prod_site "php -r 'require \"$prod_dir/_ss_environment.php\";echo SS_DATABASE_PASSWORD;'"`
readonly prod_sql_db=`ssh $prod_site "php -r 'require \"$prod_dir/_ss_environment.php\";echo SS_DATABASE_NAME;'"`

echo "Silverstripe 3.x installation detected on production site"

else

echo "Silverstripe 3.x installation not detected on production site"
exit 1

fi
}

readonly dev_vagrant_dir=/var/www/html
readonly dev_sql_user=root
readonly dev_sql_db=vagrant
readonly dev_dir=./htdocs

if [ -f "$dev_dir/_ss_environment.php" ]; then

echo "Silverstripe 3.x installation detected on development site"

else

echo "Silverstripe 3.x installation not detected on development site"
exit 1

fi

if [ "$opt_from" == "stage" -a "$opt_to" == "dev" ]; then
    detect_stage_credentials
	echo Asset syncing from stage to dev...
	rsync -a --delete-after $stage_site:$stage_dir/assets/ $dev_dir/assets
	echo Correcting asset permissions on dev...
	vagrant ssh -c "chmod -R 777 $dev_vagrant_dir/assets" &>/dev/null
	echo Database syncing from stage to dev...
	ssh $stage_site "mysqldump -u$stage_sql_user -p$stage_sql_password $stage_sql_db" > $dev_dir/dump_stage.sql
	vagrant ssh -c "mysql -u$dev_sql_user $dev_sql_db<$dev_vagrant_dir/dump_stage.sql" &>/dev/null
	echo "Updating composer modules on dev..."
	vagrant ssh -c "composer update -d=$dev_vagrant_dir" &>/dev/null
	echo "Updating database on dev..."
	vagrant ssh -c "php $dev_vagrant_dir/framework/cli-script.php dev/build \"flush=1\"" &>/dev/null
	echo Operation completed.
	exit 0;
fi

if [ "$opt_from" == "prod" -a "$opt_to" == "dev" ]; then
    detect_prod_credentials
	echo Asset syncing from prod to dev...
	rsync -a --delete-after $prod_site:$prod_dir/assets/ $dev_dir/assets
	echo Correcting asset permissions on dev...
	vagrant ssh -c "chmod -R 777 $dev_vagrant_dir/assets" &>/dev/null
	echo Database syncing from prod to dev...
	ssh $prod_site "mysqldump -u$prod_sql_user -p$prod_sql_password $prod_sql_db" > $dev_dir/dump_prod.sql
	vagrant ssh -c "mysql -u$dev_sql_user $dev_sql_db<$dev_vagrant_dir/dump_prod.sql" &>/dev/null
	echo "Updating composer modules on dev..."
	vagrant ssh -c "composer update -d=$dev_vagrant_dir" &>/dev/null
	echo "Updating database on dev..."
	vagrant ssh -c "php $dev_vagrant_dir/framework/cli-script.php dev/build \"flush=1\"" &>/dev/null
	echo Operation completed.
	exit 0;
fi

if [ "$opt_from" == "dev" -a "$opt_to" == "prod" ]; then
    detect_prod_credentials
	echo Asset syncing from dev to prod...
	rsync -a --delete-after $dev_dir/assets/ $prod_site:$prod_dir/assets/
	rsync -a --delete-after $dev_dir/slider/media/ $prod_site:$prod_dir/slider/media/
	echo Correcting asset permissions on prod...
	ssh $prod_site "chmod -R 777 $prod_dir/assets" &>/dev/null
	echo Database syncing from dev to prod...
	vagrant ssh -c "mysqldump -u$dev_sql_user $dev_sql_db > $dev_vagrant_dir/dump_dev.sql"
	scp $dev_dir/dump_dev.sql $prod_site:$prod_dir/dump_dev.sql
	ssh $prod_site "sed -i 's/http\:\/\/dev\.negombo\.it/https\:\/\/negombo\.it/g' $prod_dir/dump_dev.sql"
	ssh $prod_site "mysql -u$prod_sql_user -p$prod_sql_password $prod_sql_db<$prod_dir/dump_dev.sql"
	echo "Updating composer modules on prod..."
	ssh $prod_site "/opt/plesk/php/7.0/bin/php /usr/lib64/plesk-9.0/composer.phar --no-dev update -d$prod_dir"
	echo "Updating database on prod..."
	ssh $prod_site "/opt/plesk/php/7.0/bin/php $prod_dir/framework/cli-script.php dev/build \"flush=1\""
	echo Operation completed.
	exit 0;
fi

if [ "$opt_from" == "dev" -a "$opt_to" == "stage" ]; then
    detect_stage_credentials
	echo Asset syncing from dev to stage...
	rsync -a --delete-after $dev_dir/assets $stage_site:$stage_dir/assets/
	echo Correcting asset permissions on stage...
	ssh $stage_site "chmod -R 777 $stage_dir/assets" &>/dev/null
	echo Database syncing from dev to stage...
	vagrant ssh -c "mysqldump -u$dev_sql_user $dev_sql_db > $dev_vagrant_dir/dump_dev.sql"  &>/dev/null
	scp $dev_dir/dump_dev.sql $stage_site:$stage_dir/dump_dev.sql &>/dev/null
	ssh $stage_site "mysql -u$stage_sql_user -p$stage_sql_password $stage_sql_db<$stage_dir/dump_dev.sql" &>/dev/null
	echo "Updating composer modules on stage..."
	ssh $stage_site "/opt/plesk/php/7.0/bin/php /usr/lib64/plesk-9.0/composer.phar --no-dev update -d=$stage_dir" &>/dev/null
	echo "Updating database on stage..."
	ssh $stage_site "/opt/plesk/php/7.0/bin/php $stage_dir/framework/cli-script.php dev/build \"flush=1\"" &>/dev/null
	echo Operation completed.
	exit 0;
fi

if [ "$opt_from" == "prod" -a "$opt_to" == "stage" ]; then
    detect_prod_credentials
    detect_stage_credentials
	echo Asset syncing from prod to stage...
	ssh $stage_site "rsync -a --delete-after $prod_dir/assets/ $stage_dir/assets" &>/dev/null
	echo Correcting asset permissions on stage...
	ssh $stage_site "chmod -R 777 $stage_dir/assets" &>/dev/null
	echo Database syncing from prod to stage...
    ssh $prod_site "mysqldump -u$prod_sql_user -p$prod_sql_password $prod_sql_db | mysql -u$stage_sql_user -p$stage_sql_password $stage_sql_db"
    echo "Updating composer modules on stage..."
	ssh $stage_site "/opt/plesk/php/7.0/bin/php /usr/lib64/plesk-9.0/composer.phar --no-dev update -d=$stage_dir" &>/dev/null
	echo "Updating database on stage..."
	ssh $stage_site "/opt/plesk/php/7.0/bin/php $stage_dir/framework/cli-script.php dev/build \"flush=1\"" &>/dev/null
	echo Operation completed.
	exit 0;
fi

echo "Illegal value of parameters"
exit 1