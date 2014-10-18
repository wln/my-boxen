require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $boxen_user,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::boxen_user}"
  ]
}

File {
  group => 'staff',
  owner => $boxen_user
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => File["${boxen::config::bindir}/boxen-git-credential"],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

define atom_module ($apm_mod = $title) {
  exec { "atom_module $apm_mod":
    require => Package['atom'],
    command => "/usr/local/bin/apm install $apm_mod",
    creates => "/Users/${::boxen_user}/.atom/packages/$apm_mod"
  }
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # core modules, needed for most things
  include dnsmasq
  include git
  include hub
  include nginx

  # fail if FDE is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  # node versions
  include nodejs::v0_6
  include nodejs::v0_8
  include nodejs::v0_10

  # default ruby versions
  ruby::version { '1.9.3': }
  ruby::version { '2.0.0': }
  ruby::version { '2.1.0': }
  ruby::version { '2.1.1': }
  ruby::version { '2.1.2': }

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar'
    ]:
  }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }

  ### LOCAL ADDITIONS

  class { 'ruby::global': version => '2.1.2' }

  include java

  # Databases

  include redis

  # Git config

  git::config::global { 'alias.st': value => 'status' }
  git::config::global { 'alias.ci': value => 'commit' }
  git::config::global { 'alias.co': value => 'checkout' }
  git::config::global { 'alias.br': value => 'branch' }
  git::config::global { 'alias.lg': value => 'log --graph --pretty=format:\'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset\' --abbrev-commit' }
  git::config::global { 'color.ui': value => 'auto' }
  git::config::global { 'push.default': value => 'simple' }

  # packages

  package {
    [
      'class-dump',
      'libxml2',
      'markdown',
      'wget'
    ]:
  }

  # misc apps

  include chrome::dev

  # brewcasks

  file { "/usr/local": ensure => "directory", before => Package['atom'] }

  include brewcask

  package { [ 'arq',
              'boom-recorder',
              'dropbox',
              'evernote',
              'istat-menus',
              'onepassword',
              'sourcetree',
              'transmit',
              'vmware-fusion' ]:
            provider => 'brewcask',
            install_options => ['--appdir=/Applications'],
  }

  # atom & its packages

  package { 'atom':
            provider => 'brewcask',
            install_options => ['--appdir=/Applications'],
  }

  atom_module { [ 'language-puppet',
                  'ember-cli-helper',
                  'ember-snippets',
                  'language-emblem',
                  'autocomplete-plus',
                  'autocomplete-paths',
                  'autocomplete-snippets'
                ]:
  }

  # fonts

  homebrew::tap { 'caskroom/fonts': }
  ->
  package { [ 'font-input',
              'font-source-code-pro',
              'font-source-sans-pro',
              'font-source-serif-pro',
            ]:
            provider => 'brewcask',

  }


  # platforms

  include heroku
  package { 'awscli': }
  ruby_gem { 'tugboat for 2.1.2 ruby':
    gem => 'tugboat',
    version => '>= 0.2.0',
    ruby_version => '2.1.2',
  }

}
