# == Class: monit
#
# Puppet module to manage monit installation and configuration
#
# === Parameters
#
# [*check_interval*]
#   Interval between two checks of Monit.
#   Default: 120
#
# [*httpd*]
#   If true, Puppet enables the Monit Dashboard
#   Default: false
#
# [*httpd_port*]
#   Port of the Monit Dashboard
#   Default: 2812
#
# [*httpd_address*]
#   IP address of the Monit Dashboard
#   Default: 'locahost'
#
# [*httpd_user*]
#   User to access the Monit Dashboard
#   Default: 'admin'
#
# [*httpd_password*]
#   Password to access the Monit Dashboard
#   Default: 'monit'
#
# [*manage_firewall*]
#   If true and if puppetlabs-firewall module is present,
#   Puppet manages firewall to allow HTTP access for Monit Dashboard.
#   Default: false
#
# [*package_ensure*]
#   Ensure parameter passed to Monit Package[] resource.
#   Default: 'present'
#
# [*package_name*]
#   Name parameter passed to Monit Package[] resource.
#   Default: 'monit'
#
# [*service_ensure*]
#   Ensure parameter passed to Monit Service[] resource.
#   Default: 'running'
#
# [*service_manage*]
#   If true, Puppet manages Monit service state
#   Default: true
#
# [*service_name*]
#   Name parameter passed to Monit Service[] resource.
#   Default: 'monit'
#
# [*config_file*]
#   Path to the main config file.
#   Default: OS specific
#
# [*config_dir*]
#   Path to the config directory.
#   Default: OS specific
#
# [*logfile*]
#   Logfile directive value. Set to eg 'syslog facility log_daemon'
#   to use syslog instead of direct file logging.
#   Default: '/var/log/monit.log'
#
# [*mailserver*]
#   If set to a string, alerts will be sent by email to this mailserver.
#   Default: undef
#
# [*mailformat*]
#   Custom mail-format options hash.
#   Default: undef
#
# [*alert_emails*]
#   Array of email address to send global alerts to.
#   Default: []
#
# [*start_delay*]
#   If set, Monit will wait the specified time in seconds before it starts checking services.
#   Requires at least Monit 5.0.
#   Default: 0
#
# [*mmonit_address*]
#   Remote address of an M/Monit server to be used by Monit agent for report.
#   If set to undef, M/Monit connection is disabled.
#   Default: undef
#
# [*mmonit_port*]
#   Remote port of the M/Monit server
#   Default: '8080'
#
# [*mmonit_user*]
#   User to connect to the remote M/Monit server
#   Default: 'monit'
#
# [*mmonit_password*]
#   Password of the account used to connect to the remote M/Monit server
#   Default: 'monit'
#
# [*mmonit_without_credential*]
#   By default Monit registers credentials with M/Monit so M/Monit can smoothly
#   communicate back to Monit and you don't have to register Monit credentials manually in M/Monit.
#   It is possible to disable credential registration setting this option to 'true'.
#   Default: false
#
# === Examples
#
#  class { 'monit':
#    check_interval => 60,
#    httpd          => true,
#    httpd_address  => '172.16.0.3',
#    httpd_password => 'CHANGE_ME',
#  }
#
# === Authors
#
# Florent Poinsaut <florent.poinsaut@echoes-tech.com>
# Stas Alekseev <stas.alekseev@gmail.com>
#
# === Copyright
#
# Copyright 2014-2015 Echoes Technologies SAS, unless otherwise noted.
#
class monit (
  $check_interval            = $monit::params::check_interval,
  $httpd                     = $monit::params::httpd,
  $httpd_port                = $monit::params::httpd_port,
  $httpd_address             = $monit::params::httpd_address,
  $httpd_user                = $monit::params::httpd_user,
  $httpd_password            = $monit::params::httpd_password,
  $manage_firewall           = $monit::params::manage_firewall,
  $package_ensure            = $monit::params::package_ensure,
  $package_name              = $monit::params::package_name,
  $service_enable            = $monit::params::service_enable,
  $service_ensure            = $monit::params::service_ensure,
  $service_manage            = $monit::params::service_manage,
  $service_name              = $monit::params::service_name,
  $config_file               = $monit::params::config_file,
  $config_dir                = $monit::params::config_dir,
  $logfile                   = $monit::params::logfile,
  $mailserver                = $monit::params::mailserver,
  $mailformat                = $monit::params::mailformat,
  $alert_emails              = $monit::params::alert_emails,
  $start_delay               = $monit::params::start_delay,
  $mmonit_address            = $monit::params::mmonit_address,
  $mmonit_port               = $monit::params::mmonit_port,
  $mmonit_user               = $monit::params::mmonit_user,
  $mmonit_password           = $monit::params::mmonit_password,
  $mmonit_without_credential = $monit::params::mmonit_without_credential,
) inherits monit::params {
  if ! is_integer($check_interval) {
    fail('Invalid type. check_interval param should be an integer.')
  }
  validate_bool($httpd)
  if ! is_integer($httpd_port) {
    fail('Invalid type. http_port param should be an integer.')
  }
  validate_string($httpd_address)
  validate_string($httpd_user)
  validate_string($httpd_password)
  validate_bool($manage_firewall)
  validate_string($package_ensure)
  validate_string($package_name)
  validate_bool($service_enable)
  validate_string($service_ensure)
  validate_bool($service_manage)
  validate_string($service_name)
  validate_string($config_file)
  validate_string($config_dir)
  validate_string($logfile)
  if $mailserver {
    validate_string($mailserver)
  }
  if $mailformat {
    validate_hash($mailformat)
  }
  validate_array($alert_emails)
  validate_integer($start_delay, undef, 0)
  if($start_delay > 0 and $::monit_version < '5') {
    fail('Monit option "start_delay" requires at least Monit 5.0"')
  }
  if $mmonit_address {
    validate_string($mmonit_address)
    validate_string($mmonit_port)
    validate_string($mmonit_user)
    validate_string($mmonit_password)
    validate_bool($mmonit_without_credential)
  }

  anchor { "${module_name}::begin": } ->
  class { "${module_name}::install": } ->
  class { "${module_name}::config": } ~>
  class { "${module_name}::service": } ->
  class { "${module_name}::firewall": }->
  anchor { "${module_name}::end": }
}
