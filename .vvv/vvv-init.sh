#!/usr/bin/env bash

set -eo pipefail

run() {
  sudo -EH -u "vagrant" "$@";
}

runwp() {
  if [[ -f "/srv/www/phpcs/vendor/bin/wp" ]]; then
    run /srv/www/phpcs/vendor/bin/wp "$@";
  else
    run wp "$@";
  fi
}

echo " → ${VVV_SITE_NAME}"
cd "${VVV_PATH_TO_SITE}"

DB_NAME="${VVV_SITE_NAME}"
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*]/}

mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS \`wordpress_unit_tests\`"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO wp@localhost IDENTIFIED BY 'wp';"

if [[ -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx-default.conf" ]]; then
  run cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx-default.conf" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
fi

if [[ -d ".git" ]]; then
  rm -rf .git
fi

if [[ -f "README.md" ]]; then
  rm README.md
fi

run mkdir -p "log"
run touch "log/nginx-error.log"
run touch "log/nginx-access.log"

if [[ -f "index.php" ]]; then

  run mkdir -p "wp"
  cd "wp"
  run wp core download --locale="en_US" --version="latest"

run wp core config --dbname="${DB_NAME}" --dbuser=wp --dbpass=wp --extra-php <<PHP
define( 'AUTOMATIC_UPDATER_DISABLED', true );
define( 'DISABLE_WP_CRON', true );
define( 'WP_DEBUG', true );
define( 'WP_SCRIPT_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
define( 'WP_DISABLE_FATAL_ERROR_HANDLER', true );
define( 'WP_ENVIRONMENT_TYPE', 'development' );
define( 'WP_CONTENT_DIR', dirname( __FILE__ ) . '/content' );

if ( ! isset( \$_SERVER['HTTP_HOST'] ) ) {
  \$_SERVER['HTTP_HOST'] = '${VVV_SITE_NAME}.test';
}

define( 'WP_CONTENT_URL', 'http://' . \$_SERVER['HTTP_HOST'] . '/content' );

if ( ! defined( 'WP_INSTALLING' ) ) {
	define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] . '/wp');
	define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
}
if ( ! defined( 'ABSPATH' ) ) {
  define( 'ABSPATH', dirname( __FILE__ ) . '/wp/' );
}
PHP

  run wp core install --url="${VVV_SITE_NAME}.test" --title="${VVV_SITE_NAME}" --admin_name="admin" --admin_email="admin@example.com" --admin_password="password"

  run wp rewrite structure '/%postname%'
  run wp rewrite flush
  run wp plugin delete akismet
  run wp plugin delete hello
  run wp plugin install airplane-mode
  run wp plugin install query-monitor
  run wp plugin install rewrite-rules-inspector
  run wp plugin install user-switching
  run wp plugin install wp-crontrol

  run wp theme install twentynineteen
  run wp theme install twentytwenty
  run wp theme install twentytwentyone --activate

  cd ../

  if [[ -d "wp/content" ]]; then
    run mv wp/content content
  fi

  if [[ -d "wp/wp-content" ]]; then
    rm -rf wp/wp-content
  fi


  if [[ -f "wp/wp-config.php" ]]; then
    run mv wp/wp-config.php wp-config.php
  fi

  if [[ -f ".vvv/index.php" ]]; then
    mv .vvv/index.php index.php
  fi
fi

echo " ✓ ${VVV_SITE_NAME}"
