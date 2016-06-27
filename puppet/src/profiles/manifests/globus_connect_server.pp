# Install, configure Globus Connect Server
class profiles::globus_connect_server {
  include ::epel
  include ::ebrc_yum_repo
  include ::globus_connect_server
}