#!/usr/bin/env bash
# Provision WordPress Stable

set -eo pipefail

echo " → ${VVV_SITE_NAME}"

cd "${VVV_PATH_TO_SITE}"

DB_NAME="${VVV_SITE_NAME}"
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*]/}

mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS \`wordpress_unit_tests\`"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO wp@localhost IDENTIFIED BY 'wp';"

noroot cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx-default.conf" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"

noroot mkdir -p "log"
noroot touch "log/nginx-error.log"
noroot touch "log/nginx-access.log"

# Install and configure the latest stable version of WordPress
if [[ ! -f "index.php" ]]; then
  noroot mkdir -p "wp"
  cd "wp"
  noroot wp core download --locale="en_US" --version="latest"

noroot wp core config --dbname="${DB_NAME}" --dbuser=wp --dbpass=wp --extra-php <<PHP
define( 'AUTOMATIC_UPDATER_DISABLED', true );
define( 'DISABLE_WP_CRON', true );
define( 'WP_DEBUG', true );
define( 'WP_SCRIPT_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
define( 'WP_DISABLE_FATAL_ERROR_HANDLER', true );
define( 'WP_ENVIRONMENT_TYPE', 'development' );
define( 'WP_CONTENT_DIR', dirname( __FILE__ ) . '/content' );
define( 'WP_CONTENT_URL', 'http://' . \$_SERVER['HTTP_HOST'] . '/content' );

if ( ! defined( 'WP_INSTALLING' ) ) {
	define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] . '/wp');
	define('WP_HOME', 'http://' . \$_SERVER['HTTP_HOST']);
}
if ( ! defined( 'ABSPATH' ) ) {
  define( 'ABSPATH', dirname( __FILE__ ) . '/wp/' );
}
PHP


  noroot wp core install --url="${VVV_SITE_NAME}.test" --title="${VVV_SITE_NAME}" --admin_name="admin" --admin_email="admin@example.com" --admin_password="password"

  noroot wp plugin delete akismet
  noroot wp plugin delete hello
  noroot wp plugin install airplane-mode
  noroot wp plugin install query-monitor --activate
  noroot wp plugin install rewrite-rules-inspector --activate
  noroot wp plugin install user-switching --activate
  noroot wp plugin install wp-crontrol --activate
  noroot wp theme install twentytwentyone --activate
  cd ../

  noroot mv wp/content content
  noroot mv wp/wp-config.php wp-config.php

  echo "<?php" > index.php
  echo "define( 'WP_USE_THEMES', true );" >> index.php
  echo "require_once( 'wp/wp-blog-header.php' );" >> index.php

fi

if ! $(noroot wp core is-installed ); then
  if [ -f "/srv/database/backups/${VVV_SITE_NAME}.sql" ]; then
    # noroot wp config set DB_USER "wp"
    # noroot wp config set DB_PASSWORD "wp"
    # noroot wp config set DB_HOST "localhost"
    # noroot wp config set DB_NAME "${DB_NAME}"
    # noroot wp config set table_prefix "wp_"
    noroot wp db import "/srv/database/backups/${VVV_SITE_NAME}.sql"
  fi
fi

rm -rf .git

echo " ✓ ${VVV_SITE_NAME}"
