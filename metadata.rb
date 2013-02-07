name "graphite"
maintainer       "Scott M. Likens"
maintainer_email "scott@likens.us"
license          "Apache 2.0"
description      "Installs/Configures graphite"

version          "0.0.6"
%w{python carbon git}.each do |dp|
  depends dp
end
