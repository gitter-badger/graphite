#
# Cookbook Name:: graphite_collectd
# Recipe:: default
#
# Copyright 2013, Scott M. Likens
#
#
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

if node.has_key?("ec2")
  chef_gem "di-ruby-lvm" do
    action :install
  end
  chef_gem "di-ruby-lvm-attrib" do
    action :install
  end
  package "lvm2"
  lvm_volume_group 'vg00' do
    physical_volumes [ "/dev/xvdb", "/dev/xvdc" ]
    logical_volume 'graphite' do
      size '75%VG'
      filesystem 'ext4'
      mount_point({ :location => '/opt/graphite/storage', :options => 'noatime,nodiratime' })
      stripes 2
      action :create
    end
  end
else
package "lvm2"
end

# We want the pg gem, so we can cleanly use the database cookbook.
include_recipe "graphite::pg"

# install the carbon suite
carbon_install "stable" do
  action :git
end

# Start port of the cache query ports
cache_query_port = 7000
# Start port of the line receiver
line_receiver_port = 3001
# Start port of the pickle receiver
pickle_receiver_port = 3101
# Relay line receiver start
relay_line_receiver_port = 2031
relay_pickle_receiver_port = 2041
# When using CPU Affinity, we should let it know what the starting cpu is.  If you have other cpu's used by other resources, bump accordingly.
cpu = 0
# destionations array
dst = []
# carbon query port array
cqp = []
dstplus = []


carbon_install "stable" do
  action :git
end

("a".."l").each do |ci|
  carbon_cache "carbon_cache-" + ci do
  action [:create,:start]
    init_style "runit"
    cpu_affinity cpu
    carbon_instance ci
    line_listner({"line_receiver_interface" => "0.0.0.0", "line_receiver_port" => line_receiver_port })
    pickle_listner({"pickle_receiver_interface" => "0.0.0.0", "pickle_receiver_port" => pickle_receiver_port })
    udp_listner({"enable_udp_listner" => "False", "udp_receiver_interface" => "0.0.0.0", "udp_receiver_port" => line_receiver_port })
    cache_query({"cache_query_interface" => "0.0.0.0", "cache_query_port" => cache_query_port })
    storage_schema({ :all => { :pattern => "(.*)", :retentions => "10s:14d, 60s:30d, 600s:1y" } })
    storage_aggregation({:min => { :pattern => "\.min$", :xfilesfactor => "0.1", :aggregationmethod => "min" }, :max => { :pattern => "\.max$", :xfilesfactor => "0.1", :aggregationmethod => "max" }, :sum => { :pattern => "\.count$", :xfilesfactor => "0", :aggregationmethod => "sum" }, :default_average => { :pattern => ".*", :xfilesfactor => "0.5", :aggregationmethod => "average"}})
    dst << ["127.0.0.1:#{pickle_receiver_port}"]
    cqp << ["\"127.0.0.1:#{cache_query_port}:#{ci}\""]
    dstplus << "127.0.0.1:#{pickle_receiver_port}:#{ci}"
    cpu+= 1           
    cache_query_port+= 1
    line_receiver_port+= 1
    pickle_receiver_port+= 1
  end
end

("a".."c").each do |cr|
  carbon_relay "carbon_relay-" + cr do
    relay_rules({ "default" => { "default" => "true", "destinations" => dstplus, "continue" => String.new, "pattern" => String.new } })
    line_listner({"line_receiver_interface" => "0.0.0.0", "line_receiver_port" => relay_line_receiver_port })
    pickle_listner({"pickle_receiver_interface" => "0.0.0.0", "pickle_receiver_port" => relay_pickle_receiver_port})
    destinations dstplus
    relay_instance cr
    cpu_affinity cpu
    init_style "runit"
    cpu+= 1
    relay_pickle_receiver_port+= 1
    relay_line_receiver_port+= 1
    action [:create,:start]
  end
end

cookbook_file "/opt/graphite/conf/graphTemplates.conf" do
  source "graphTemplates.conf"
  owner "graphite"
  group "graphite"
  cookbook "graphite"
end

graphite_web "graphite-web-stable" do
  action :git
end

package "libpq-dev"
package "postgresql-client-common"
package "postgresql-client-9.1"
python_pip "psycopg2" do
  virtualenv "/opt/graphite"
  action :install
  user "graphite"
end

postgres_server = search(:node, 'name:postgres_graphite').first

postgresql_database "graphite" do
  connection ({:host => postgres_server.ec2.public_hostname || postgres_server.hostname, :port => 5432, :username => 'postgres', :password => postgres_server.postgresql.password})
  action :create
end

begin
graphite_federated = search(:node, 'name:graphite_statsd').first
rescue
graphite_fedearted = nil
end
if graphite_federated.nil?
  graphite_web "graphite-web" do
  action [:create,:start]
  init_style "runit"
  workers "24"
  backlog 65535
  listen_port 8080
  listen_address "0.0.0.0"
  cpu_affinity 1
  user "graphite"
  group "graphite"
  graphite_home "/opt/graphite"
  carbonlink_hosts cqp
  cpu_affinity "13-24"
  debug "True"
  database_engine "postgresql_psycopg2"
  database ({ :name => 'graphite', :user => 'postgres', :password => postgres_server.postgresql.password, :host => postgres_server.ec2.public_hostname || postgres_server['network']['interfaces']['eth1']['addresses'].select {|address, data| data["family"] == "inet" }.keys.first, :port => 5432 })
  end
else
  graphite_web "graphite-web" do
  action [:create,:start]
  init_style "runit"
  workers "24"
  backlog 65535
  listen_port 8080
  listen_address "0.0.0.0"
  cpu_affinity 1
  user "graphite"
  group "graphite"
  graphite_home "/opt/graphite"
  carbonlink_hosts cqp
  cpu_affinity "13-24"
  debug "True"
  database_engine "postgresql_psycopg2"
  cluster_servers graphite_federated.ec2.public_hostname + ":8080" || node['network']['interfaces']['eth1']['addresses'].select {|address, data| data["family"] == "inet" }.keys.first + ":8080"
  database ({ :name => 'graphite', :user => 'postgres', :password => postgres_server.postgresql.password, :host => postgres_server.ec2.public_hostname || postgres_server['network']['interfaces']['eth1']['addresses'].select {|address, data| data["family"] == "inet" }.keys.first, :port => 5432 })
  end
end

package "hatop"

haproxy_source_file = "haproxy_1.5-dev17-1ubuntu1_#{node['kernel']['machine'] =~ /x86_64/ ? "amd64" : "i386"}.deb"
remote_file Chef::Config[:file_cache_path] + "/" + haproxy_source_file do
  source "https://mopub-debs.s3.amazonaws.com/haproxy/#{node['platform_version']}/#{node['kernel']['machine'] =~ /x86_64/ ? "amd64" : "i386"}/#{haproxy_source_file}"
  not_if { ::File.exists?(Chef::Config[:file_cache_path] + haproxy_source_file) }
end

package "haproxy" do
  source Chef::Config[:file_cache_path] + "/" + haproxy_source_file
  provider Chef::Provider::Package::Dpkg
  action :install
  not_if { File.exists?("/usr/sbin/haproxy") }
end
template "/etc/default/haproxy" do
  source "haproxy-default.erb"
  owner "root"
  group "root"
  mode 0644
  cookbook "haproxy_lwrp"
end
listen_temp=Array.new  

listen_temp << { "name" => "carbon-relay-plain 0.0.0.0:2003", "mode" => "tcp", "server" => ["127.0.0.1"], "start_port" => 2031, "instance_count" => 3}
listen_temp << { "name" => "carbon-relay-pickle 0.0.0.0:2004", "mode" => "tcp", "server" => ["127.0.0.1"], "start_port" => 2041, "instance_count" => 3}

haproxy_lwrp_lb "haproxy" do
  global({"maxconn" => 65535, "ulimit-n" => 160000, "user" => "haproxy", "group" => "haproxy", "stats" => "socket /var/run/haproxy.sock mode 0600 level admin user root" })
  defaults({ "log" => "global", "mode" => "http", "option" => "dontlognull", "balance" => "leastconn", "srvtimeout" => 60000, "contimeout" => 5000, "retries" => 3,"option" => "redispatch\noption contstats"})
  listen(listen_temp)
  action :create
end

apache_module "proxy" 
apache_module "proxy_http"
apache_module "proxy_balancer"
apache_module "headers"
apache_module "rewrite"
apache_site "default" do
  enable false
end

template "/etc/apache2/sites-available/graphite" do
  source "apache2.graphite.conf.erb"
  variables({
              :balancermember => ["127.0.0.1:8080"],
              :timeout => 1500,
              :serveradmin => "abuse@mopub.com",
              :maxattempts => 2
            })
end

apache_site "graphite" do
  enable true
end  
