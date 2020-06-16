# @summary Install and configure ProFTPD
#
# @param config_template
#   Specify which erb template to use.
#
# @param default_config
#   Set to `false` to disable loading of the default configuration. Defaults to `true`.
#
# @param manage_config_file
#   Set to `false` to disable managing of the ProFTPD configuration file(s).
#
# @param manage_ftpasswd_file
#   Set to `false` to disable managing of the ProFTPD ftpasswd file.
#
# @param package_ensure
#   Overwrite the package `ensure` parameter.
#
# @param package_manage
#   Set to `false` to disable package management. Defaults to `true`.
#
# @param service_manage
#   Set to `false` to disable service management. Defaults to `true`.
#
# @param service_enable
#   Set to `false` to disable the ProFTPD system service. Defaults to `true`.
#
# @param service_ensure
#   Overwrite the service `ensure` parameter.
#
# @param prefix
#   Prefix to be added to all paths. Only required on certain operating systems
#   or special installations.
#
# @param config_mode
#   File mode to be used for config files. Defaults to `0644`.
#
# @param prefix_bin
#   Path to the ProFTPD binary.
#
# @param config
#   Path to the ProFTPD configuration file.
#
# @param base_dir
#   Directory for additional configuration files.
#
# @param log_dir
#   Directory for log files.
#
# @param run_dir
#   Directory for runtime files (except PIDfile).
#
# @param packages
#   An array of packages which should be installed.
#
# @param service_name
#   The name of the ProFTPD service.
#
# @param user
#   Set the user under which the server will run.
#
# @param group
#   Set the group under which the server will run.
#
# @param pidfile
#   Path and name of the PID file for the ProFTPD service.
#
# @param scoreboardfile
#   Path and name of the ScoreboardFile for the ProFTPD service.
#
# @param ftpasswd_file
#   Path and name of the ftpasswd file.
#
# @param anonymous_options
#   An optional hash containing the default options to configure ProFTPD for
#   anonymous FTP access. Use this to overwrite these defaults.
#
# @param anonymous_enable
#   Set to `true` to enable loading of the `$anonymous_options` hash.
#
# @param default_options
#   A hash containing a set of working default options for ProFTPD. This should
#   make it easy to get a running service and to overwrite a few settings.
#
# @param load_modules
#   A hash of optional ProFTPD modules to load. It is possible to load modules
#   in a specific order by using the order attribute.
#
# @param options
#   Specify a hash containing options to either overwrite the default options or
#   configure ProFTPD from scratch. Will be merged with `$default_options` hash
#   (as long as `$default_config` is not set to `false`).
#
# @param authuserfile_source
#   Inject the AuthUserFile by defining a Puppet source (e.g. puppet:///modules/mymodule/ftpd.passwd)
#
# @param authgroupfile_source
#   Inject the AuthGroupFile by defining a Puppet source (e.g. puppet:///modules/mymodule/ftpd.group)
#
class proftpd (
  # module parameters
  String[1]                      $config_template      = $proftpd::params::config_template,
  Boolean                        $default_config       = $proftpd::params::default_config,
  Boolean                        $manage_config_file   = $proftpd::params::manage_config_file,
  Boolean                        $manage_ftpasswd_file = $proftpd::params::manage_ftpasswd_file,
  String                         $package_ensure       = $proftpd::params::package_ensure,
  Boolean                        $package_manage       = $proftpd::params::package_manage,
  Boolean                        $service_manage       = $proftpd::params::service_manage,
  Boolean                        $service_enable       = $proftpd::params::service_enable,
  String                         $service_ensure       = $proftpd::params::service_ensure,
  # os-specific parameters
  Optional[Stdlib::Absolutepath] $prefix               = $proftpd::params::prefix,
  Stdlib::Filemode               $config_mode          = $proftpd::params::config_mode,
  Stdlib::Absolutepath           $prefix_bin           = $proftpd::params::prefix_bin,
  Stdlib::Absolutepath           $config               = $proftpd::params::config,
  Stdlib::Absolutepath           $base_dir             = $proftpd::params::base_dir,
  Stdlib::Absolutepath           $log_dir              = $proftpd::params::log_dir,
  Stdlib::Absolutepath           $run_dir              = $proftpd::params::run_dir,
  Array[String[1]]               $packages             = $proftpd::params::packages,
  String[1]                      $service_name         = $proftpd::params::service_name,
  String[1]                      $user                 = $proftpd::params::user,
  String[1]                      $group                = $proftpd::params::group,
  Stdlib::Absolutepath           $pidfile              = $proftpd::params::pidfile,
  Stdlib::Absolutepath           $scoreboardfile       = $proftpd::params::scoreboardfile,
  Stdlib::Absolutepath           $ftpasswd_file        = $proftpd::params::ftpasswd_file,
  # proftpd configuration
  Hash                           $anonymous_options    = $proftpd::params::anonymous_options,
  Boolean                        $anonymous_enable     = $proftpd::params::anonymous_enable,
  Hash                           $default_options      = $proftpd::params::default_options,
  Hash                           $load_modules         = $proftpd::params::load_modules,
  Hash                           $options              = $proftpd::params::options,
  Optional[Stdlib::Filesource]   $authuserfile_source  = $proftpd::params::authuserfile_source,
  Optional[Stdlib::Filesource]   $authgroupfile_source = $proftpd::params::authgroupfile_source,
) inherits proftpd::params {
  # resource relationships
  class { 'proftpd::install': }
  -> class { 'proftpd::config': }
  ~> class { 'proftpd::service': }

  if $load_modules {
    create_resources(proftpd::module, $load_modules, {})
  }
}
