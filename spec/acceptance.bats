#!/usr/bin/env bats

# BIN="./dist/kit-darwin-amd64"
BIN="crystal run bin/kit.cr --"

global_setup(){
  make clean > /dev/null && \
    crystal build bin/kit.cr -o dist/kit-darwin-amd64 > /dev/null && \
    chmod +x "$BIN" > /dev/null
}

global_teardown(){
  make clean > /dev/null
}

setup(){
  TEST_TMP_DIR="$(mktemp -d)"
}

teardown(){
  rm -rf "$TEST_TMP_DIR"
}

# global_setup

@test "invoking kit with a stedolan/jq" {
  run $BIN --install stedolan/jq -o "$TEST_TMP_DIR"
  [ "$status" -eq 0 ]
  run ls -la "$TEST_TMP_DIR/jq"
  [ "$status" -eq 0 ]
}

@test "invoking kit with a zph/kit" {
  run $BIN --install zph/kit -o "$TEST_TMP_DIR"
  [ "$status" -eq 0 ]
  run ls -la "$TEST_TMP_DIR/kit"
  [ "$status" -eq 0 ]
}

@test "fails gracefully with exit 1 when output file exists" {
  mkdir "$TEST_TMP_DIR/jq"
  run $BIN --install stedolan/jq -o "$TEST_TMP_DIR"
  [ "$status" -eq 1 ]
}

@test "unpacks multiple binaries from a tar.gz" {
  run $BIN --install file://./spec/fixtures/3binaries.tar.gz -o "$TEST_TMP_DIR" --binaries bin1,bin2,bin3
  [ "$status" -eq 0 ]
  ls "$TEST_TMP_DIR/bin1"
  [ "$status" -eq 0 ]
  ls "$TEST_TMP_DIR/bin2"
  [ "$status" -eq 0 ]
  ls "$TEST_TMP_DIR/bin3"
  [ "$status" -eq 0 ]
}

@test "unpacks multiple binaries from a zip" {
  run $BIN --install file://./spec/fixtures/3binaries.zip -o "$TEST_TMP_DIR" --binaries bin1,bin2,bin3
  [ "$status" -eq 0 ]
  ls "$TEST_TMP_DIR/bin1"
  [ "$status" -eq 0 ]
  ls "$TEST_TMP_DIR/bin2"
  [ "$status" -eq 0 ]
  ls "$TEST_TMP_DIR/bin3"
  [ "$status" -eq 0 ]
}

@test "invoking kit with a config file" {
  skip
  run crystal run bin/kit.cr -- --config "$HOME/src/kit/spec/config_test.yaml"
  [ "$status" -eq 0 ]
}

# global_teardown
