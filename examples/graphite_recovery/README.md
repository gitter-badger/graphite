Description
===========

This cookbook should provide a pattern to quickly stand up an recovery statsd endpoint in ec2 or any other hosting provider that can give us fast enough disks.  This cookbook will not support our current graphite infrastructure, only in disaster recovery.

Requirements
============

1. [carbon](http://github.com/damm/carbon/)
  Installs the **Carbon Cache** and **Carbon Relay** Services
2. [Upstart](http://upstart.ubuntu.com/)
  Pull requests accepted to support other init styles
3. [Python](http://github.com/opscode-cookbooks/python/)
  Provides virtualenv support and the pip provider
4. [Postgresql](http://github.com/opscode-cookbooks/postgresql/)
  Datastore for Graphite.
5. [Database](http://github.com/opscode-cookbooks/database/)
  To be able to create the graphite database via Chef.

+ postgresql database serve to host the schema.  SQLite3 does not scale.

Recipes
============

default.rb
----------

This recipe should do the following:
  + Start 12 carbon-caches
  + Start 1 carbon-relay configured with consistent-hashing into the 12 caches
    + it should listen on udp as well
  + Using gunicorn start the Django UI (Graphite-web) on port 8080
  + Load the initial data with has some recent Dashboards
  

Usage
==================

* First bootstrap a postgresql recipe, currently the node name is hard coded so copy and paste this.

    knife ec2 server create -I ami-fd20ad94 --flavor m1.large -G default -x ubuntu -N graphite_recovery_postgres -Z us-east-1d -S yourkey -r 'role[postgresql_server]'

* Once that is done, now start an hi1.4xlarge to host our carbon-cache/relay/etc

    ec2-run-instances ami-fd20ad94 -t hi1.4xlarge -k smlikens --block-device-mapping=sdb=ephemeral0 --block-device-mapping=sdc=ephemeral1 --block-device-mapping=sdd=ephemeral2 --block-device-mapping=sde=ephemeral3

* Wait for it to come up, then bootstrap it with this recipe.

    knife bootstrap  -r "recipe[graphite_recovery]" -N graphite_recovery --environment ops $ip

License and Author
==================
Author:: Scott M. Likens <scott@likens.us>

Copyright 2013, Scott M. Likens

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
  
