#
# Cookbook Name:: graphite
# Recipe:: default
#
# Copyright 2012, Scott M. Likens
#
#

gem "di-ruby-lvm" do
  action :install
end
gem "di-ruby-lvm-attrib" do
  action :install
end
gem "pg"
package "lvm2"
cache_query_port = 7000
line_receiver_port = 2100
pickle_receiver_port = 2200
cpu = 0
# destionations array
dst = []
# carbon query port array
cqp = []
dstplus = []
group "graphite" do
  action :create
end
user "graphite" do
  group "graphite"
  shell "/bin/bash"
  home "/opt/graphite"
  supports :manage_home => true
end
directory "/opt/graphite" do
  owner "graphite"
  group "graphite"
  mode 0755
  recursive true
  action :create
end

lvm_volume_group 'vg00' do
  physical_volumes [ "/dev/xvdb" ]
  logical_volume 'graphite' do
    size '75%VG'
    filesystem 'ext4'
    mount_point({ :location => '/opt/graphite/storage', :options => 'noatime,nodiratime' })
    # stripes 2
    action :create
  end
end

execute "chown -R graphite:graphite /opt/graphite" do
  action :run
end
carbon_install "stable" do
  action :git
end

("a".."l").each do |ci|
  carbon_cache "carbon_cache-#{ci}" do 
    action [:create,:start]
    init_style "runit"
    cpu_affinity cpu
    carbon_instance ci
    line_listner({"line_receiver_interface" => "0.0.0.0", "line_receiver_port" => line_receiver_port })
    pickle_listner({"pickle_receiver_interface" => "0.0.0.0", "pickle_receiver_port" => pickle_receiver_port })
    udp_listner({"enable_udp_listner" => "False", "udp_receiver_interface" => "0.0.0.0", "udp_receiver_port" => line_receiver_port })
    cache_query({"cache_query_interface" => "0.0.0.0", "cache_query_port" => cache_query_port })
    storage_schema({ :all => { :pattern => "(.*)", :retentions => "60s:90d, 120s:1y" } })
    storage_aggregation({:min => { :pattern => "\.min$", :xfilesfactor => "0.1", :aggregationmethod => "min" }, :max => { :pattern => "\.max$", :xfilesfactor => "0.1", :aggregationmethod => "max" }, :sum => { :pattern => "\.count$", :xfilesfactor => "0", :aggregationmethod => "sum" }, :default_average => { :pattern => ".*", :xfilesfactor => "0.5", :aggregationmethod => "average"}})
    cpu+= 1           
    cache_query_port+= 1
    line_receiver_port+= 1
    pickle_receiver_port+= 1
    dst << ["127.0.0.1:#{pickle_receiver_port}"]
    cqp << ["\"127.0.0.1:#{cache_query_port}:#{ci}\""]
    dstplus << "127.0.0.1:#{pickle_receiver_port}:#{ci}"
  end
end

carbon_relay "statsd" do
  relay_rules({ "default" => { "default" => "true", "destinations" => dstplus, "continue" => String.new, "pattern" => String.new } })
  line_listner({"line_receiver_interface" => "0.0.0.0", "line_receiver_port" => 2003 })
  pickle_listner({"pickle_receiver_interface" => "0.0.0.0", "pickle_receiver_port" => 2004 })
  destinations dstplus
  relay_instance "a"
  cpu_affinity "13"
  init_style "runit"
  action [:create,:start]
end

graphite_web "graphite-web-stable" do
  action :git
end

cookbook_file "/opt/graphite/conf/graphTemplates.conf" do
  source "graphTemplates.conf"
  owner "graphite"
  group "graphite"
end

package "libpq-dev"
package "postgresql-client-common"
package "postgresql-client-9.1"

python_pip "psycopg2" do
  virtualenv "/opt/graphite"
  action :install
end
postgres_server = search(:node, 'name:graphite_recovery_postgres').first

postgresql_database "graphite" do
  connection ({:host => postgres_server.ec2.public_hostname, :port => 5432, :username => 'postgres', :password => postgres_server.postgresql.password})
  action :create
end

graphite_web "graphite-web" do
  initial_data_template "initial_data.json.erb"
  cookbook "graphite_recovery"
  workers "24"
  init_style "runit"
  listen_port 8080
  listen_address "0.0.0.0"
  backlog 65535
  debug "True"
  cpu_affinity "13-24"
  carbonlink_hosts cqp
  database_engine "postgresql_psycopg2"
  graphite_packages({ "graphite-web" => "0.9.10", "gunicorn" => "0.16.1", "Django" => "1.3", "django-tagging" => "0.3.1", "simplejson" => "2.1.6", "Twisted" => "11.0.0", "python-memcached" => "1.47", "txAMQP" => "0.4", "pytz" => "2012b", "psycopg2" => "2.4.5" })
  database({ :name => 'graphite', :user => 'postgres', :password => postgres_server.postgresql.password, :host => postgres_server.ec2.public_hostname, :port => 5432 })
  action [:create,:start]
end
