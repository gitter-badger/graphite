#
# Cookbook Name:: graphite
# Recipe:: default
#
# Copyright 2012, Scott M. Likens
#
#


carbon_cache "carbon_cache" do
  action [:install,:config,:start]
  cpu_affinity "1"
end

carbon_relay "carbon_relay" do
  action [:config,:start]
end

cookbook_file "/opt/graphite/conf/graphTemplates.conf" do
  source "graphTemplates.conf"
  owner "graphite"
  group "graphite"
end
graphite_web "graphite_web" do
  action [:git,:create,:start]
end
