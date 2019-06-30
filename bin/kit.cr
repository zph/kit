#!/usr/bin/env crystal

require "../src/kit"
file = if ARGV[0]?
         ARGV[0]
       else
         # Default
         "kit.yaml"
       end

config = File.open(file) do |file|
  YAML.parse(file)
end
Kit::CLI.call(config)
