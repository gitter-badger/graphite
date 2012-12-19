action :install do
  group new_resource.group do
    action :create
  end
  user new_resource.user do
    group new_resource.group
    shell "/bin/bash"
    home new_resource.graphite_home
    supports :manage_home => true
  end
  directory new_resource.graphite_home do
    owner new_resource.user
    group new_resource.group
    mode 0755
    recursive true
    action :create
  end
  python_virtualenv new_resource.graphite_home do
    interpreter new_resource.python_interpreter
    owner new_resource.user
    group new_resource.group
    action :create
  end
  graphite_packages = new_resource.graphite_packages.collect do |pkg,ver|
    python_pip pkg do
      version ver
      virtualenv new_resource.graphite_home
      action :install
    end
  end
  package "libcairo2-dev"
  python_pip "http://cairographics.org/releases/py2cairo-1.8.10.tar.gz" do
    virtualenv new_resource.graphite_home
  action :install
end
  new_resource.updated_by_last_action(true)
end
action :config do
  directory new_resource.graphite_home + "/storage/log/webapp" do
    action :create
    recursive true
    owner new_resource.user
    group new_resource.group
    mode 0755
  end

  template new_resource.graphite_home + "/webapp/graphite/local_settings.py" do
    source new_resource.local_settings_template
    owner new_resource.user
    group new_resource.group
    cookbook new_resource.cookbook
    variables({
                :debug => new_resource.debug,
                :time_zone => new_resource.time_zone,
                :log_rendering_performance => new_resource.log_rendering_performance,
                :log_cache_performance => new_resource.log_cache_performance,
                :documentation_url => new_resource.documentation_url,
                :smtp_server => new_resource.smtp_server,
                :use_ldap_auth => new_resource.use_ldap_auth,
                :database_engine => new_resource.database_engine,
                :database => new_resource.database,
                :cluster_servers => new_resource.cluster_servers,
                :memcache_hosts => new_resource.memcache_hosts,
                :rendering_hosts => new_resource.rendering_hosts,
                :remote_rendering => new_resource.remote_rendering,
                :standard_dirs => new_resource.standard_dirs,
                :carbonlink_hosts => new_resource.carbonlink_hosts
              })
    mode 0655
  end

  template new_resource.graphite_home + "/webapp/graphite/initial_data.json" do
    source new_resource.initial_data_template
    owner new_resource.user
    group new_resource.group
    cookbook new_resource.cookbook
    mode 0655
  end
  execute "syncdb" do
    command new_resource.graphite_home + "/bin/django-admin.py syncdb --settings=graphite.settings --noinput --pythonpath=webapp"
    cwd new_resource.graphite_home
    not_if { node['graphite']['initial_data_loaded'] == "true" }
  end
  node.set['graphite']['initial_data_loaded'] = "true"
  node.save unless Chef::Config[:solo]
  case new_resource.init_style
  when "upstart"
    template "/etc/init/graphite-web.conf" do
      source new_resource.web_template
      cookbook new_resource.cookbook
      owner "root"
      group "root"
      mode 0644
      variables({
                  :workers => new_resource.workers,
                  :backlog => new_resource.backlog,
                  :timeout => new_resource.timeout,
                  :listen_port => new_resource.listen_port,
                  :listen_address => new_resource.listen_address,
                  :cpu_affinity => new_resource.cpu_affinity,
                  :user => new_resource.user,
                  :group => new_resource.group,
                  :graphite_home => new_resource.graphite_home
                })
    end
  else
    log "not implemented"
    fatal
  end
  new_resource.updated_by_last_action(true)
end
action :start do
  case new_resource.init_style
  when "upstart"
    service "graphite-web" do
      provider Chef::Provider::Service::Upstart
      action [:enable,:start]
    end
  end
  new_resource.updated_by_last_action(true)
end
action :stop do
  case new_resource.init_style
  when "upstart"
    service "graphite-web" do
      provider Chef::Provider::Service::Upstart
      action [:stop,:disable]
    end
  else
    log "not supported"
    fatal
  end
  new_resource.updated_by_last_action(true)
end
