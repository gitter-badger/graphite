maintainer       "Scott M. Likens"
maintainer_email "scott@likens.us"
license          "Apache 2.0"
description      "Installs/Configures graphite_recovery"

version          "0.1"
%w{carbon graphite lvm}.each do |dp|
  depends dp
end
