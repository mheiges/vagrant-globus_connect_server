# Install, configure Globus Connect Server
class profiles::globus_connect_server {
  include ::epel
  include ::ebrc_yum_repo
  include ::globus_connect_server

  # for troubleshooting
  package { ['lsof', 'mlocate', 'nmap']:
    ensure => 'installed',
  }

  # 2811 tcp,        # control channel
  # 50000-51000 tcp, # gridftp_incoming data channel I/O
  # 50000-51000 udp, # gridftp_incoming data chanel I/O
  # 7512 tcp,        # myproxy
  #
  firewalld_rich_rule { 'Globus Connect control channel':
    ensure    => present,
    zone      => 'public',
    port      => {
      'port'     => $globus_connect_server::config::gsc_gridftp_control_channel_port,
      'protocol' => 'tcp',
    },
    action    => 'accept',
  }

  firewalld_rich_rule { 'Globus MyProxy':
    ensure    => present,
    zone      => 'public',
    port      => {
      'port'     => $globus_connect_server::config::gcs_myproxy_port,
      'protocol' => 'tcp',
    },
    action    => 'accept',
  }

  ['udp','tcp'].each |$protocol| {
    firewalld_rich_rule { "Globus Connect data channel, ${protocol}":
      ensure    => present,
      zone      => 'public',
      port      => {
        'port'     => inline_template(
          "'<%= scope['::globus_connect_server::config::gcs_gridftp_incomingportrange'].gsub(/[:,]/, '-') %>'"
        ),
        'protocol' => $protocol,
      },
      action    => 'accept',
    }
  }

  # Hack to fix Vagrant landrush DNS NATing clobbered by firewalld
  # reload. Without this the resource server setup will fail due to
  # failure to resolve the iCAT hostname.
  Firewalld_rich_rule {
    subscribe => Exec['save_landrush_iptables'],
    notify    => Exec['restore_landrush_iptables'],
  }
  exec { 'save_landrush_iptables':
    command     => '/sbin/iptables-save -t nat > /root/landrush.iptables',
    refreshonly => true,
  }
  exec { 'restore_landrush_iptables':
    command     => '/sbin/iptables-restore < /root/landrush.iptables',
    refreshonly => true,
  }


}
