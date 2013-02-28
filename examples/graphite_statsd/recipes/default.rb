#
# Cookbook Name:: graphite_statsd
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

directory "/opt/graphite" do
  owner "graphite"
  group "graphite"
  mode 0755
  recursive true
  action :create
end

include_recipe "graphite::pg"
# Start port of the cache query ports
cache_query_port = 7000
# Start port of the line receiver
line_receiver_port = 3001
# Start port of the pickle receiver
pickle_receiver_port = 3101
# Relay line receiver start
relay_line_receiver_port = 2013
relay_pickle_receiver_port = 2014
# When using CPU Affinity, we should let it know what the starting cpu is.  If you have other cpu's used by other resources, bump accordingly.
cpu = 0
# destionations array
dst = []
# carbon query port array
cqp = []
dstplus = []
cluster = []

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

carbon_relay "carbon_relay-a" do
  relay_rules({ "default" => { "default" => "true", "destinations" => dstplus, "continue" => String.new, "pattern" => String.new } })
  line_listner({"line_receiver_interface" => "0.0.0.0", "line_receiver_port" => relay_line_receiver_port })
  pickle_listner({"pickle_receiver_interface" => "0.0.0.0", "pickle_receiver_port" => relay_pickle_receiver_port})
  destinations dstplus
  relay_instance "a"
  cpu_affinity cpu
  init_style "runit"
  cpu+= 1
  action [:create,:start]
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
  connection ({:host => postgres_server.ec2.public_hostname, :port => 5432, :username => 'postgres', :password => postgres_server.postgresql.password})
  action :create
end

begin
  graphite_federated = search(:node, 'name:graphite_collectd').first
rescue
    graphite_federated = nil
end


if graphite_federated.nil?
log "graphite_federated is nil" do
    level :debug
end
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
    database ({ :name => 'graphite', :user => 'postgres', :password => postgres_server.postgresql.password, :host => postgres_server.ec2.public_hostname, :port => 5432 })
  end
else
  if graphite_federated.has_key?("ec2") 
    cluster << "#{graphite_federated.ec2.public_hostname}:8080"
    log "cluster is #{graphite_federated.ec2.public_hostname}" do
      level :debug
    end
  else
    log "cluster is #{graphite_federated['network']['interfaces']['eth1']['addresses'].select {|address, data| data["family"] == "inet" }.keys.first}" do
      level :debug
    end
    cluster << "#{graphite_federated['network']['interfaces']['eth1']['addresses'].select {|address, data| data["family"] == "inet" }.keys.first}:8080"
  end
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
    cluster_servers cluster
    database ({ :name => 'graphite', :user => 'postgres', :password => postgres_server.postgresql.password, :host => postgres_server.ec2.public_hostname, :port => 5432 })
  end
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
