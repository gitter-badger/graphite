#
# Cookbook Name:: graphite
# Recipe:: default
#
# Copyright 2012, Scott M. Likens
#
#


carbon_cache "sample" do
  action [:install,:config,:start]
  cpu_affinity "1"
end

carbon_relay "sample" do
  action [:config,:start]
end

graphite_web "sample" do
  action [:install,:config,:start]
end
