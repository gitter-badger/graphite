site :opscode

metadata

cookbook "build-essential"
cookbook "runit", "1.1.0"
cookbook "git"
cookbook "carbon", git: "git://github.com/damm/carbon.git", branch: "0.3.0"

group :integration do
  cookbook "apt"
  cookbook "yum"
  cookbook "minitest-handler"
end