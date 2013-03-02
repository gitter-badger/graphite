#
# Cookbook Name:: graphite_render
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

include_recipe "graphite::pg"

# install the carbon suite
carbon_install "stable" do
  action :git
end

graphite_web "graphite-web-stable" do
  action :git
end

graphite_web "graphite-web" do
  action [:create,:start]
  init_style "runit"
  workers "#{node[:cpu][:total].to_i}"
  backlog 65535
  listen_port 8080
  listen_address "0.0.0.0"
  user "graphite"
  group "graphite"
  graphite_home "/opt/graphite"
  debug "True"
end
