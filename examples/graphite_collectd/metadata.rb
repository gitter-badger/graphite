name             'graphite_collectd'
maintainer       'Scott M. Likens'
maintainer_email 'scott@likens.us'
license          'All rights reserved'
description      'Installs/Configures graphite_collectd'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
depends "carbon"
depends "graphite"
depends "database"
depends "lvm"
depends "haproxy_lwrp"
depends "apache2"
