# vvv-wp

This is a customized site template for [VVV](https://varyingvagrantvagrants.org/docs/en-US/site-templates/).

## Using this template
All you need is the following in your `config/config.yml`. Make sure you replace `sandbox` with your site name.

```yaml
  sandbox:
    repo: https://github.com/bradp/vvv-wp.git
    hosts:
      - sandbox.test
```


## Notes
- There aren't any options, you just configure the host and you're off to the races. The host is assumed to be `<site name>.test`, so make sure you use that.
- On provisions after the first one, nothing will change on the filesystem. It's up to you to update WordPress, themes, and plugins.
- Credentials will be set as
  - username: `admin`
  - password: `password`

## Features & Differences from default site template
- Cleans up after itself, removing the `.git` folder from this site template and the `README.md`
- File structure set to have a `wp/` folder and a `content/` folder
- Sets permalinks to `/%postname`
- Creates `wordpress_unit_tests` database if it doesn't exist
- Debug & development constants set in `wp-config.php`
  - `AUTOMATIC_UPDATER_DISABLED`
  - `DISABLE_WP_CRON`
  - `WP_DEBUG`
  - `WP_SCRIPT_DEBUG`
  - `WP_DEBUG_LOG`
  - `WP_DEBUG_DISPLAY`
  - `WP_DISABLE_FATAL_ERROR_HANDLER`
  - `WP_ENVIRONMENT_TYPE`
- Installs themes
  - `twentynineteen`
  - `twentytwenty`
  - `twentytwentyone` (set as active)
- Installs & activates a few development plugins
  - [`airplane-mode`](https://wordpress.org/plugins/airplane-mode)
  - [`query-monitor`](https://wordpress.org/plugins/query-monitor)
  - [`rewrite-rules-inspector`](https://wordpress.org/plugins/rewrite-rules-inspector)
  - [`user-switching`](https://wordpress.org/plugins/user-switching)
  - [`wp-crontrol`](https://wordpress.org/plugins/wp-crontrol)
