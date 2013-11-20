source 'https://rubygems.org'

group :test do
  gem 'chef'
  gem 'rspec'
  gem 'foodcritic'
end

group :integration do
  gem 'berkshelf',       '~> 2.0'
  gem 'test-kitchen',    '~> 1.0.0.beta'
  gem 'kitchen-vagrant', '~> 0.11'
  gem 'kitchen-lxc', :git => "https://github.com/portertech/kitchen-lxc.git", :tag => 'v0.0.1.beta2'
  gem 'kitchen-docker', :git => "https://github.com/portertech/kitchen-docker.git", :tag => 'v0.10.0'
end