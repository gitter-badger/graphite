#!/usr/bin/env bats

@test "localhost should serve graphite browser" {
  [ "$(wget -qO- localhost:8080 | grep 'Graphite Browser')" ]
}
