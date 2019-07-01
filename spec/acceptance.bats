@test "invoking kit with a stedolan/jq" {
  run crystal run bin/kit.cr -- --install stedolan/jq -o "$BATS_TMPDIR"
  [ "$status" -eq 0 ]
}

@test "invoking kit with a zph/kit" {
  run crystal run bin/kit.cr -- --install zph/kit -o "$BATS_TMPDIR"
  [ "$status" -eq 0 ]
}

@test "invoking kit with a config file" {
  run crystal run bin/kit.cr -- --config "$HOME/src/kit/spec/config_test.yaml"
  [ "$status" -eq 0 ]
}
