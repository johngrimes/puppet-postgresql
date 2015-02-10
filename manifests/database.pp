define postgresql::database($user) {
  exec { "create-${name}-db":
    unless  => "psql -l | grep ${name}",
    command => "createdb -O ${user} ${name}",
    user    => 'postgres',
    require => [
      Service['postgresql'],
      Postgresql::User[$user]
    ]
  }
}
