Description
===========

This cookbook provides resources and providers to install and configure [Graphite](http://graphite.wikidot.com/) Web Interface under [virtualenv](http://pypi.python.org/pypi/virtualenv).  Currently supported resources:

* Graphite web (`web`)

Requirements
============

1. [carbon](http://github.com/damm/carbon/)
  Installs the **Carbon Cache** and **Carbon Relay** Services
3. [Python](http://github.com/opscode-cookbooks/python/)
  Provides virtualenv support and the pip provider
3. [Runit](http://github.com/opscode-cookbooks/runit/)
  Minimum version of 1.0.6

Usage
============

There are 3 examples in the examples/ directory for your review.  Additionally there are examples in the test directory for simple examples.  

*Note* the examples below are not intended for usage on EC2 primarily.  Hosting a Metrics collector can require a massive amount of I/O depending on your schema.  It is possible to host an statsd collector on a *hi1.4xlarge* and this cookbook can do that.

```shell ec2-run-instances ami-fd20ad94 -t hi1.4xlarge -k something --block-device-mapping=sdb=ephemeral0 --block-device-mapping=sdc=ephemeral1 --block-device-mapping=sdd=ephemeral2 --block-device-mapping=sde=ephemeral3```

* examples/graphite_statsd/
Host many carbon agents configured behind a single carbon-relay to be able to recieve and store metrics.  Configure apache on port 80 to provide [cors](http://www.html5rocks.com/en/tutorials/cors/).

* examples/graphite_collectd/
Host many carbon agents configured behind many carbon-relays able to recieve and store metrics.  Configure HAProxy to listen on the standard carbon-relay ports and load balance further.  Apache is configured on port 80 for *cors*.

* examples/graphite_render/
Our graphite servers have dual E5-2620 CPU's running at 2.0Ghz which can lead to slow down cairo.  We found that having a E3-1230v2 can get the data over the wire and generate the image and push it to your client faster than our graphite servers could generate that same image.  Configures graphite-web only to listen on 8080, no carbon-agents are configured.

Benchmarks
=======================

1. graphite_statsd running on an Dual E5-2620 has been known to handle up to 1million metrics without dropping any metrics.
2. graphite_collectd running on an Dual E5-2620 has been known to handle up to 3million metrics without dropping any metrics.
  Using HAProxy is configured to have a connection timeout of 5000 which can lead to the tcp connection needing to be re-established every 83 minutes.

Resources and Providers
=======================

This cookbook provides one resource and the corresponding provider.

`web.rb`
-------------

Installs and Configured [Graphite Web](https://github.com/graphite-project/graphite-web) from [Pypi](http://pypi.python.org/pypi/graphite-web)

Actions:

* `install` - installs graphite-web
* `create` - configures graphite-web
* `start` - starts the graphite-web service
* `stop` - stops the graphite-web service
* `git` - install graphite-web from *stable sources*

Attribute Parameters:

* `graphite_stable_base_git_uri` - String - default - `https://github.com/graphite-project/`
* `graphite_stable_packages` - Hash - default - `{ "graphite-web" => "0.9.x", "whisper" => "0.9.x" }`
* `initial_data_template` - String - default -  `initial_data.json.erb`
* `python_interpreter` - String - default - `python2.7`
* `init_style` - String - default `upstart`
* `cookbook` - String - default - `graphite`
* `user` - String - default - `graphite`
* `group` - String - default - `graphite`
* `workers` - Fixnum - default - `1`
* `timeout` - Fixnum - default - `300`
* `backlog` - Fixnum - default - `655355`
* `listen_port` - Fixnum, - default - `8080`
* `listen_address` - String - default - `0.0.0.0`
* `cpu_affinity` - String
* `local_settings_template` - String - default `local_settings.py.erb`
* `web_template` - String - default `graphite-web.init.erb`
* `graphite_home` - String - default - `/opt/graphite`
* `graphite_packages` - Hash - default - `{ "graphite-web" => "0.9.10", "gunicorn" => "0.16.1", "Djan
go" => "1.3", "django-tagging" => "0.3.1", "simplejson" => "2.1.6", "Twisted" => "11.0.0", "python-memcached" => "1.47"
, "txAMQP" => "0.4", "pytz" => "2012b" }`
* `debug` - String - default `False`
* `time_zone` - String - default - `UTC`
* `log_rendering_performance, :kind_of => String, :default => "False"
* `log_cache_performance, :kind_of => String, :default => "False"
* `documentation_url` - String - Configures the `DOCUMENTATION_URL` in local_settings.py
* `smtp_server` - String - configures the `SMTP_SERVER` setting in local_settings.py
* `use_ldap_auth` - String - Not fully implemented, please use your own local_settings.py template if you require this behavior
* `database_engine` - String - default *sqlite3*
* `database` - Hash - default - `{ :name => 'graphite', :user => 'graphite', :password => String.new, :host => String.new, :port => 5432 }`
* `cluster_servers` - Array
* `memcache_hosts` - Array
* `rendering_hosts` - Array
* `remote_rendering` - Aray
* `data_dirs` - String
* `carbonlink_hosts` - Array
 
Contributing
------------

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github


License and Author
==================
Author:: Scott M. Likens <scott@spam.likens.us>

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
  
