#!/usr/bin/env bats

BIN="bin/run"

setup(){
  TEST_TMP_DIR="$(mktemp -d)"
}

teardown(){
  rm -rf "$TEST_TMP_DIR"
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
  run $BIN -- --config "$HOME/src/kit/spec/config_test.yaml"
  [ "$status" -eq 0 ]
  ls "$TEST_TMP_DIR/teleport"
  [ "$status" -eq 0 ]
  ls "$TEST_TMP_DIR/tsh"
  [ "$status" -eq 0 ]
  ls "$TEST_TMP_DIR/chamber"
  [ "$status" -eq 0 ]
  ls "$TEST_TMP_DIR/aws-vault"
  [ "$status" -eq 0 ]
}
