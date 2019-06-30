#!/usr/bin/env crystal

require "../src/kit"

file = ARGV[0]?

if file
  config = File.open(file) do |file|
    YAML.parse(file)
  end
  Kit::CLI.call(config)
end
