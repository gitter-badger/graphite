#
# Cookbook Name:: graphite
# Recipe:: default
#
# Copyright 2012, Scott M. Likens
#
#

gem "di-ruby-lvm"
gem "di-ruby-lvm-attrib"
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
  physical_volumes [ "/dev/xvdb", "/dev/xvdc" ]
  logical_volume 'graphite' do
    size '75%VG'
    filesystem 'ext4'
    mount_point({ :location => '/opt/graphite/storage', :options => 'noatime,nodiratime' })
    stripes 2
    action :create
  end
end

execute "chown -R graphite:graphite /opt/graphite" do
  action :run
end

carbon_cache "install" do
  action :install
end

("a".."l").each do |ci|
  carbon_cache "carbon_cache-#{ci}" do 
    action [:config,:start]
    cpu_affinity cpu
    carbon_instance ci
    line_listner({"line_receiver_interface" => "0.0.0.0", "line_receiver_port" => line_receiver_port })
    pickle_listner({"pickle_receiver_interface" => "0.0.0.0", "pickle_receiver_port" => pickle_receiver_port })
    udp_listner({"enable_udp_listner" => "False", "udp_receiver_interface" => "0.0.0.0", "udp_receiver_port" => line_receiver_port })
    cache_query({"cache_query_interface" => "0.0.0.0", "cache_query_port" => cache_query_port })
    storage_schema({ :all => { :pattern => "(.*)", :retentions => "60s:90d, 120s:1y" } })
    cpu+= 1           
    cache_query_port+= 1
    line_receiver_port+= 1
    pickle_receiver_port+= 1
    dst << ["127.0.0.1:#{pickle_receiver_port}"]
    cqp << ["127.0.0.1:#{cache_query_port}:#{ci}"]
    dstplus << "127.0.0.1:#{pickle_receiver_port}:#{ci}"
  end
end

carbon_relay "sample" do
  relay_rules({ "default" => { "default" => "true", "destinations" => dstplus, "continue" => String.new, "pattern" => String.new } })
  line_listner({"line_receiver_interface" => "0.0.0.0", "line_receiver_port" => 2003 })
  pickle_listner({"pickle_receiver_interface" => "0.0.0.0", "pickle_receiver_port" => 2004 })
  destinations dstplus
  relay_instance "a"
  cpu_affinity "13"
  action [:config,:start]
end

graphite_web "sample" do
  initial_data_template "initial_data.json.erb"
  cookbook "graphite_recovery"
  workers "24"
  cpu_affinity "13-24"
  carbonlink_hosts cqp
  action [:install,:config,:start]
end
