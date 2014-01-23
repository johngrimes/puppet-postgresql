define postgresql::s3_backup (
    $backup_dir,
    $s3_path,
    $s3_config,
    $user,
    $group
  ) {
  $db_name = $title

  package { 's3cmd': ensure => present }

  file { $backup_dir:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '660'
  }

  $log_dir = "${backup_dir}/log"
  file { $log_dir:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '660',
    require => File[$backup_dir]
  }

  file { "/usr/local/bin/backup_${db_name}":
    ensure  => file,
    content => template('postgresql/s3_backup.sh.erb'),
    owner   => $user,
    group   => $group,
    mode    => '740',
    require => File[$backup_dir],
  }

  file { "/usr/local/bin/restore_${db_name}":
    ensure  => file,
    content => template('postgresql/s3_restore.sh.erb'),
    owner   => $user,
    group   => $group,
    mode    => '740',
    require => File[$backup_dir],
  }

  file { "/home/${user}/.s3cfg":
    ensure  => file,
    content => $s3_config,
    owner   => $user,
    group   => $group,
    mode    => '400',
    require => User[$user]
  }

  cron { 'backup_db':
    command => "nice /usr/local/bin/backup_${db_name} >> ${log_dir}/backup_${db_name}.log 2>&1",
    user    => $user,
    minute  => '33',
    hour    => '1'
  }

  logrotate::conf { "backup_${db_name}":
    content => template('postgresql/backup.logrotate.erb'),
  }
}
