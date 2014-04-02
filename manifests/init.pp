class postgresql (
    $shared_buffers = '24MB',
    $effective_cache_size = '128MB',
    $max_connections = 100,
    $shmmax = '33554432'
  ) {

  include filesystem::data
  include monit

  $pg_dir = '/data/postgresql'
  $data_dir = "${pg_dir}/main"
  $pid_file = '/var/run/postgresql/9.1-main.pid'
  $listen_port = 5432

  file { $pg_dir:
    ensure  => directory,
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '600',
    require => File['/data']
  }

  file { $data_dir:
    ensure  => directory,
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '600',
    require => File['/data'],
    notify  => [
      Exec['postgresql-stop'],
      Exec['postgresql-initdb']
    ]
  }

  package { 'postgresql-9.1': ensure => present }
  package { 'postgresql-server-dev-9.1': ensure => present }

  sysctl::value { 'kernel.shmmax': value => $shmmax }

  exec { 'postgresql-stop':
    command     => '/etc/init.d/postgresql stop',
    refreshonly => true,
    require     => Package['postgresql-9.1']
  }

  exec { 'postgresql-initdb':
    command     => "rm -rf ${data_dir}/* && /usr/lib/postgresql/9.1/bin/initdb -D ${data_dir} --locale en_AU.UTF-8",
    user        => 'postgres',
    require     => [
      Package['postgresql-9.1'],
      File[$data_dir]
    ],
    refreshonly => true,
    notify      => File['pg_hba.conf']
  }

  service { 'postgresql':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [
      Package['postgresql-9.1'],
      File['pg_hba.conf'],
      File['postgresql.conf'],
      File[$data_dir],
      Sysctl::Value['kernel.shmmax']
    ]
  }

  group { 'postgres': ensure => present }

  user { 'postgres':
    ensure     => present,
    gid        => 'postgres',
    groups     => ['postgres'],
    require    => Group['postgres']
  }

  file { 'pg_hba.conf':
    path    => "${data_dir}/pg_hba.conf",
    ensure  => file,
    content => template('postgresql/pg_hba.conf.erb'),
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '640',
    require => File[$data_dir],
    notify  => Service['postgresql']
  }

  file { 'postgresql.conf':
    path    => '/etc/postgresql/9.1/main/postgresql.conf',
    ensure  => file,
    content => template('postgresql/postgresql.conf.erb'),
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '644',
    require => Package['postgresql-9.1'],
    notify  => Service['postgresql']
  }

  monit::conf { 'postgresql':
    content => template('postgresql/postgresql.monit.erb'),
    require => Service['postgresql']
  }
}
