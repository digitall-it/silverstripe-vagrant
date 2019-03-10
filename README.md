# silverstripe-vagrant

Vagrant box based on Centos 7 with provisioners for Silverstripe 3 and 4.

Includes a migrator preconfigured for Plesk based servers (requires passwordless SSH shell access) to sync uploaded assets and database. Issues a `composer update` and a `dev/build?flush=1` server-side.
