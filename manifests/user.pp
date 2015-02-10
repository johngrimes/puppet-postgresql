define postgresql::user($password) {
  exec { "create-${name}-user":
    unless  => "psql -d postgres -c \"\\du\" | grep ${name}",
    command => "createuser ${name} -s -d -R && psql -c \"ALTER USER ${name} WITH PASSWORD '${password}';\"",
    user    => 'postgres',
    require => Service['postgresql']
  }
}
