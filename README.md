# puppet-proftpd

[![Build Status](https://github.com/markt-de/puppet-proftpd/actions/workflows/ci.yaml/badge.svg)](https://github.com/markt-de/puppet-proftpd/actions/workflows/ci.yaml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/markt/proftpd.svg)](https://forge.puppetlabs.com/markt/proftpd)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/markt/proftpd.svg)](https://forge.puppetlabs.com/markt/proftpd)

#### Table of Contents

1. [Overview](#overview)
2. [Usage](#usage)
    * [Beginning with proftpd](#beginning-with-proftpd)
    * [Using Hiera](#using-hiera)
3. [Reference](#reference)
    * [Syntax](#syntax)
    * [Classes and Parameters](#classes-and-parameters)
4. [Limitations](#limitations)
    * [OS Compatibility](#os-compatibility)
    * [Template Issues](#template-issues)
5. [Development](#development)
6. [Contributors](#contributors)

## Overview

A Puppet module for ProFTPD, hiera-friendly, highly configurable and well-tested.

## Usage

### Beginning with proftpd

This example will install packages, setup a minimal configuration and activate the service for you:

    class { 'proftpd': }

Loading additional modules is easy too:

    class { 'proftpd':
      load_modules => {
        ban => {},
        tls => {},
        sql => {},
      }
    }

It is simple to add new options or overwrite the defaults in the configuration root or any (sub) section:

    class { 'proftpd':
      options => {
        'ROOT'  => {
          'ServerName'   => 'FTP server',
          'MaxInstances' => '10',
        },
        'IfModule mod_vroot.c' => {
          'VRootEngine' => 'on',
        },
      },
    }

NOTE: You don't need to take care for section brackets or closing tags. The module will add this automatically.

Enabling anonymous login and customizing it's default options works the same way:

    class { 'proftpd':
      anonymous_enable => true,
      options          => {
        'Anonymous ~ftp'        => {
          'Directory uploads/*' => {
            'Limit STOR'        => {
              'AllowAll'        => true,
              'DenyAll'         => false,
            },
          },
        },
      },

You may opt to disable the default configuration and do everything from scratch:

    class { 'proftpd':
      default_config => false,
      options => {...}
    }

(Here the options hash must contain all options required to run ProFTPD.)

### Using Hiera

You're encouraged to define your configuration using Hiera, especially if you plan to disable the default configuration:

    proftpd::default_config: false
    # load modules in a specific order if necessary
    proftpd::load_modules:
      sql:
        order: 1
      sql_mysql:
        order: 2
      quotatab:
        order: 3
      quotatab_sql:
        order: 4
      rewrite:
        order: 5
      ban: {}
      tls: {}

    proftpd::options:
      ROOT:
        ServerType: 'standalone'
        DefaultServer: 'on'
        ScoreboardFile: '/var/run/proftpd.scoreboard'
        DelayTable: '/var/run/proftpd.delay'
        ControlsSocket: '/var/run/proftpd.socket'
        User: 'www'
        Group: 'www'
        Umask: '006'
        UseReverseDNS: 'off'
        DefaultRoot: '~ !'
        DefaultChdir: '/var/ftp'
        ServerName: '%{facts.networking.fqdn}'
        Port: '21'
        PassivePorts: '49152 65534'
        TransferLog: 'NONE'
        LogFormat:
          - 'default "%h %l %u %t \"%r\" %s %b"'
          - 'auth "%t %v [%P] %h \"%r\" %s"'
          - 'access "%h %l %u %t \"%r\" %s %b"'
        ExtendedLog:
          - '/var/log/proftpd/access.log INFO,DIRS,MISC,READ,WRITE access'
          - '/var/log/proftpd/auth.log AUTH auth'
        MaxClients: '20 "Connection limit reached (%m)."'
        MaxInstances: '20'
        MaxClientsPerHost: '15 "Connection limit reached (%m)."'
        MaxClientsPerUser: '10 "Connection limit reached (%m)."'
        TLSEngine: 'on'
        TLSProtocol: 'SSLv23'
        TLSRequired: 'off'
        TLSOptions: 'NoCertRequest'
        TLSCipherSuite: 'ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP'
        TLSVerifyClient: 'off'
        TLSRSACertificateFile: '/etc/ssl/%{facts.networking.fqdn}.crt'
        TLSRSACertificateKeyFile: '/etc/ssl/%{facts.networking.fqdn}.key'
        TLSLog: '/var/log/proftpd/tls.log'
      Global:
        RequireValidShell: 'off'
        UseFtpUsers: 'on'
        AllowRetrieveRestart: 'on'
        AllowStoreRestart: 'on'
        AllowOverwrite: 'yes'
        AccessGrantMsg: '"Login OK"'
        IdentLookups: 'off'
        ServerIdent: 'on "FTP Service"'
        AllowForeignAddress: 'on'
        DirFakeUser: 'on www'
        DirFakeGroup: 'on www'
        PathDenyFilter: '"(\.ftpaccess)$"'
        ListOptions: '"-a"'
        MaxLoginAttempts: '2'
        AuthUserFile: '/etc/proftpd/proftpd.passwd'
        AuthGroupFile: '/etc/proftpd/proftpd.group'
        TimeoutLogin: '1800'
        TimeoutIdle: '1800'
        TimeoutStalled: '1800'
        TimeoutNoTransfer: '1800'
      'Directory /':
        AllowOverwrite: 'on'
      'VirtualHost 127.0.1.1':
        ServerName: '"FTP Server 1"'
        PassivePorts: '60000 65534'
      'IfModule mod_rewrite.c':
        RewriteEngine: 'on'
        RewriteLog: '/var/log/proftpd/rewrite.log'
        RewriteMap:
          - |
            replace int:replaceall
                RewriteCondition        %m ^(STOR)$
                RewriteRule             ^(.*)$  "${replace:/$1/ /_}"
          - |
            replace int:replaceall
                RewriteCondition        %m ^(STOR)$
                RewriteRule             ^(.*)$  "${replace:/$1/\?/_}"
          - |
            replace int:replaceall
                RewriteCondition        %m ^(STOR)$
                RewriteRule             ^(.*)$  "${replace:/$1/Ü/UE}"
      'Directory /mnt/exchange/user1/*':
        RewriteCondition:
          - |-
            '%f "^[[:cntrl:] ]+"
                RewriteRule "^[[:cntrl:] ]+([^[:cntrl:]]+)" $1'
          - |-
            '%f "[[:cntrl:] ]+$"
                RewriteRule "([^[:cntrl:]]+)[[:cntrl:] ]+$" $1'
          - |-
            '%f "[[:cntrl:]]"
                RewriteRule "([^[:cntrl:]]+)[[:cntrl:]]*([^[:cntrl:]]*)[[:cntrl:]]*([^[:cntrl:]]*)" $1$2$3'  

## Reference

### Syntax

You may want to use the `$options` parameter to overwrite default configuration options or build a ProFTPD configuration from scratch. There are few things you need to know:

* `sections`: ProFTPD's configuration uses a number of &lt;sections&gt;. You create a new section by specifying a hash, the module's erb template will do the rest for you. This works for special cases like &lt;IfDefine X&gt; too.
* `ROOT`: To add items to the root of the ProFTPD configuration, use this namespace.
* `false`: Setting a value to 'false' will remove the item from the configuration.
* `multiple values`: If you want to specify multiple values for the same configuration item (i.e. `LogFormat` or `ExtendedLog`), you need to specify these values as an array.

### Classes and Parameters

Classes and parameters are documented in [REFERENCE.md](REFERENCE.md).

## Limitations

### OS Compatibility

This module was tested on FreeBSD, CentOS and Debian. Please open a new issue if your operating system is not supported yet, and provide information about problems or missing features.

### Template Issues

The `proftpd.conf.erb` template... sucks. It suffers from code repetition. Furthermore it is limited to only four nested configuration sections (which should still be enough, even for rather complex configurations). If you come up with a better idea please let me know.

## Development

Please use the github issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.

## Contributors

This module is heavily inspired by and in part based on the following modules:

* [arioch/puppet-proftpd](https://github.com/arioch/puppet-proftpd)
* [takumin/puppet-proftpd](https://github.com/takumin/puppet-proftpd)
* [cegeka/puppet-proftpd](https://github.com/cegeka/puppet-proftpd)

See the `LICENSE` file for further information.
