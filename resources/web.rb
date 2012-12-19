actions :config,:install,:start,:stop

attribute :init_style, :king_of => String, :default => "upstart"
attribute :template_cookbook, :kind_of => String, :default => "graphite"
attribute :user, :kind_of => String, :default => "graphite"
attribute :group, :kind_of => String, :default => "graphite"
attribute :workers, :kind_of => String, :default => [node[:cpu][:total].to_i]
attribute :timeout, :kind_of => Fixnum, :default => 300
attribute :backlog, :kind_of => Fixnum, :default => 655355
attribute :listen_port, :kind_of => Fixnum, :default => 8080
attribute :listen_address, :kind_of => String, :default => "0.0.0.0"
attribute :local_settings_template, :kind_of => String, :default => "local_settings.py"
attribute :web_template, :kind_of => String, :default => "graphite-web.init.erb"
attribute :graphite_home, :kind_of => String, :default => "/opt/graphite"
attribute :graphite_packages, :kind_of => Hash, :default => { "graphite-web" => "0.9.10", "gunicorn" => "0.16.1" }
attribute :debug, :kind_of => String, :default => "False"
attribute :time_zone, :kind_of => String, :default => "UTC"
attribute :log_rendering_performance, :kind_of => String, :default => "False"
attribute :log_cache_performance, :kind_of => String, :default => "False"
attribute :documentation_url, :kind_of => String, :default => String.new
attribute :smtp_server, :kind_of => String, :default => String.new
# FIXME: This should actually do something
attribute :use_ldap_auth, :kind_of => String, :default => String.new
attribute :database_engine, :kind_of => String, :default => String.new
# "postgresql_psycopg2"
attribute :database, :kind_of => Hash, :default => { :name => 'graphite', :user => 'graphite', :password => String.new, :host => String.new, :port => Fixnum.new }
attribute :cluster_servers, :kind_of => Array, :default => Array.new
attribute :memcache_hosts, :kind_of => Array, :default => Array.new
attribute :rendering_hosts, :kind_of => Array, :default => Array.new
attribute :remote_rendering, :king_of => String, :default => "False"
attribute :standard_dirs, :kind_of => Array, :default => Array.new
attribute :carbonlink_hosts, :kind_of => Array, :default => Array.new

def initialize(*args)
  super
  @action = :install
  @run_context.include_recipe ["build-essential","python","python::pip","python::virtualenv"]
end
