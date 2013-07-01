site :opscode

metadata

cookbook "build-essential"
cookbook "runit", "1.1.4"
cookbook "git"
cookbook "carbon", git: "git://github.com/damm/carbon.git", branch: "master"

group :integration do
  cookbook "apt"
  cookbook "yum"
  cookbook "minitest-handler"
  cookbook "graphite_test", path: "test/cookbooks/graphite_test"
end