#!/usr/bin/env bats

BIN="./dist/kit-darwin-amd64"

global_setup(){
  make clean && make build
}

global_teardown(){
  make clean
}

setup(){
  TEST_TMP_DIR="$(mktemp -d)"
}

teardown(){
  rm -rf "$TEST_TMP_DIR"
}

global_setup

@test "invoking kit with a stedolan/jq" {
  run "$BIN" --install stedolan/jq -o "$TEST_TMP_DIR"
  [ "$status" -eq 0 ]
  run ls -la "$TEST_TMP_DIR/jq"
  [ "$status" -eq 0 ]
}

@test "invoking kit with a zph/kit" {
  run "$BIN" --install zph/kit -o "$TEST_TMP_DIR"
  [ "$status" -eq 0 ]
  run ls -la "$TEST_TMP_DIR/kit"
  [ "$status" -eq 0 ]
}

@test "fails gracefully with exit 1 when output file exists" {
  mkdir "$TEST_TMP_DIR/jq"
  run "$BIN" --install stedolan/jq -o "$TEST_TMP_DIR"
  [ "$status" -eq 1 ]
}

@test "invoking kit with a config file" {
  skip
  run crystal run bin/kit.cr -- --config "$HOME/src/kit/spec/config_test.yaml"
  [ "$status" -eq 0 ]
}

global_teardown
