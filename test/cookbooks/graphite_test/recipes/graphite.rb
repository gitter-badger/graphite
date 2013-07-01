#
# Cookbook Name:: graphite
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


graphite_web "graphite-web-stable" do
  action :git
end

cookbook_file "/opt/graphite/conf/graphTemplates.conf" do
  source "graphTemplates.conf"
  owner "graphite"
  group "graphite"
  cookbook "graphite"
end

graphite_web "graphite-web" do
  action :create
  init_style "runit"
  workers "2"
  backlog 65535
  listen_port 8080
  listen_address "0.0.0.0"
  cpu_affinity 1
  user "graphite"
  group "graphite"
  graphite_home "/opt/graphite"
end

