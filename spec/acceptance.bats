#!/usr/bin/env bats

setup(){
  TEST_TMP_DIR="$(mktemp -d)"
}

teardown(){
  rm -rf "$TEST_TMP_DIR"
}

@test "invoking kit with a stedolan/jq" {
  run crystal run bin/kit.cr -- --install stedolan/jq -o "$TEST_TMP_DIR"
  [ "$status" -eq 0 ]
  run ls -la "$TEST_TMP_DIR/jq"
  [ "$status" -eq 0 ]
}

@test "invoking kit with a zph/kit" {
  run crystal run bin/kit.cr -- --install zph/kit -o "$TEST_TMP_DIR"
  [ "$status" -eq 0 ]
  run ls -la "$TEST_TMP_DIR/kit"
  [ "$status" -eq 0 ]
}

@test "invoking kit with a config file" {
  skip
  run crystal run bin/kit.cr -- --config "$HOME/src/kit/spec/config_test.yaml"
  [ "$status" -eq 0 ]
}
