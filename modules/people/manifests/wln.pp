class people::wln {
  $home = "/Users/${::boxen_user}"

  git::config::global { 'user.name': value => 'Lee Nussbaum' }
  git::config::global { 'user.email': value => 'lee@leenussbaum.com' }

  # osx::recovery_message { 'lee@leenussbaum.com | 917-757-1024': }

  $bash_it_dir = "${home}/.bash_it"
  repository { "${bash_it_dir}":
        source => 'revans/bash-it'
  }
  file { "${bash_it_dir}/custom/boxen.bash":
        require => Repository[$bash_it_dir],
        content => "source ${boxen::config::home}/env.sh"
  }

  # Projects

  include projects::all

  # Projects: Resource clones

}

