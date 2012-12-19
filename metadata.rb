maintainer       "Scott M. Likens"
maintainer_email "scott@likens.us"
license          "Apache 2.0"
description      "Installs/Configures graphite"

version          "0.0.2"
%w{python carbon}.each do |dp|
  depends dp
end
