define postgresql::fs_backup (
    $backup_dir,
    $user,
    $group,
    $days_to_keep = 7
  ) {
  $db_name = $title

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
    content => template('postgresql/fs_backup.sh.erb'),
    owner   => $user,
    group   => $group,
    mode    => '740',
    require => File[$backup_dir]
  }

  file { "/usr/local/bin/restore_${db_name}":
    ensure  => file,
    content => template('postgresql/fs_restore.sh.erb'),
    owner   => $user,
    group   => $group,
    mode    => '740',
    require => File[$backup_dir]
  }

  cron { 'backup_db':
    command => "nice /usr/local/bin/backup_${db_name} >> ${log_dir}/backup_${db_name}.log 2>&1",
    user    => $user,
    minute  => '33',
    hour    => '1'
  }

  cron { 'trim_backups':
    command => "nice find ${backup_dir}/*.sql.gz -mtime +${days_to_keep} -exec rm {} \\;",
    user    => $user,
    minute  => '17',
    hour    => '2'
  }

  logrotate::conf { "backup_${db_name}":
    content => template('postgresql/backup.logrotate.erb')
  }
}
