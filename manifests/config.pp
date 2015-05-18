# Class sshd::config
#
# Manages ssh configuration
#
#
class sshd::config (
  $ldap_uri        = $::sshd::ldap_uri,
  $ldap_base       = $::sshd::ldap_base,
  $ldap_tls_cacert = $::sshd::ldap_tls_cacert,
){

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7' {
    selboolean { 'authlogin_nsswitch_use_ldap':
      persistent => true,
      value      => 'on',
    }
  }

  # OpenSSH merged RH's patch as ov version 6.2
  if versioncmp('6.2', $::opensshversion) < 1 {
    $auth_user_cmd = 'AuthorizedKeysCommandUser'
  } else {
    $auth_user_cmd = 'AuthorizedKeysCommandRunAs'
  }

  # Support oddjob on RH>= 7 for selinux
  if versioncmp($::operatingsystemrelease, '7.0') >= 0 {
    $_pam_source = 'puppet:///modules/sshd/sshd.oddjob'
  } else {
    $_pam_source = 'puppet:///modules/sshd/sshd'
  }

  file { '/etc/ssh/ldap.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('sshd/ldap.conf.erb'),
  }

  file { '/etc/ssh/sshd_config':
    ensure  => 'file',
    mode    => '0400',
    owner   => 'root',
    group   => 'root',
    require => Package['openssh-server'],
    notify  => Service[ 'sshd' ],
    content => template('sshd/sshd_config.erb'),
  }

  file { '/etc/pam.d/sshd':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => $_pam_source,
  }

}