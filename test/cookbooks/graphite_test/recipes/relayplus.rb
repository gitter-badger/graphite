#
# Cookbook Name:: graphite
# Recipe:: default
#
# Copyright 2013, Scott M. Likens
#
#

carbon_install "carbon_stable" do
  action :git
end

carbon_cache "carbon-cache-a" do
  action :create
  init_style "runit"
  cpu_affinity 1
end

carbon_relay "carbon-relay-a" do
  cpu_affinity 0
  init_style "runit"
  action :create
end

graphite_web "graphite-web_stable" do
  action :git
end

cookbook_file "/opt/graphite/conf/graphTemplates.conf" do
  source "graphTemplates.conf"
  owner "graphite"
  cookbook "graphite"
  group "graphite"
end


graphite_web "graphite-web" do
  action :create
  init_style "runit"
  workers 2
  backlog 65535
  listen_port 8080
  listen_address "0.0.0.0"
  cpu_affinity 1
  user "graphite"
  group "graphite"
  graphite_home "/opt/graphite"
end
