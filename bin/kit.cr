#!/usr/bin/env crystal

require "../src/kit"

require "option_parser"

install = nil
destination = FileUtils.pwd
config = nil
binaries = nil
version = nil
sha256 = nil
help = false
filter = ".*"

o = OptionParser.parse! do |parser|
  parser.banner = ["Usage: kit -c kit.yaml",
                   "From Github      : kit -i stedolan/jq -o ~/bin",
                   "From Github Long : kit --install github://stedolan/jq#jq-1.6 --output ~/bin --binaries jq",
                   "From URI         : kit --install https://example.com/foobar.tar.gz -o dist --binaries foo,bar"].join("\n")
  parser.on("-c CONFIG", "--config=CONFIG", "Configuration kit.yaml") { |k| config = k }
  parser.on("-i URI", "--install=URI", "Specifies the URI of package to install") { |n| install = n }
  parser.on("-o FOLDER", "--output=FOLDER", "Specifies the output destination") { |n| destination = n }
  parser.on("-b BINARIES", "--binaries=BINARIES", "Comma separated list of names") { |n| binaries = n.split(",").map { |i| i.strip } }
  parser.on("-f FILTER", "--filter=FILTER", "Download link filter") { |n| filter = n }
  parser.on("-t TAG", "--tag=TAG", "Specifies the tag to install") { |n| version = n }
  parser.on("-s SHA", "--sha256=SHA", "Specifies the sha256 to verify") { |n| sha256 = n }
  parser.on("-h", "--help", "Show help") { help = true; puts parser }
  parser.on("-v", "--version", "Show version") { puts Kit::VERSION; exit }
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

module Config
  class General
    include YAML::Serializable

    @[YAML::Field(key: "binaries")]
    property binaries : Array(String)

    @[YAML::Field(key: "post_install")]
    property post_install : Array(String)?

    @[YAML::Field(key: "output")]
    property output : String?

    @[YAML::Field(key: "version_cmd")]
    property version_cmd : String?
  end

  class Platform
    include YAML::Serializable

    @[YAML::Field(key: "link")]
    property link : String

    @[YAML::Field(key: "version")]
    property version : String

    @[YAML::Field(key: "sha256")]
    property sha256 : String?

    @[YAML::Field(key: "filter")]
    property filter : String?
  end

  class Binary
    include YAML::Serializable

    @[YAML::Field(key: "general")]
    property general : General

    @[YAML::Field(key: "platform")]
    property platform : Hash(String, Platform)
  end

  class Core
    include YAML::Serializable

    @[YAML::Field(key: "version")]
    property version : String

    @[YAML::Field(key: "defaults")]
    property defaults : Hash(String, String)?

    @[YAML::Field(key: "binaries")]
    property binaries : Hash(String, Binary)
  end
end

def by_config(config : String)
  c = File.open(config) do |file|
    Config::Core.from_yaml(file)
  end
  by_config(c)
end

def by_config(config : YAML::Any)
  Kit::CLI.call(config)
end

def by_config(config : Config::Core)
  Kit::CLI.call(config)
end

def by_config(config : Nil)
  raise("Invalid config file")
end

def individual_install(uri, destination, binaries : Nil, version, sha256, filter)
  raise("Missing binaries flag data")
end

def individual_install(uri, destination, binaries : Array(String), version, sha256, filter)
  config = {
    "version"  => "v1",
    "binaries" => {
      binaries.first => {
        "general" => {
          "version_cmd"  => nil,
          "output"       => destination,
          "binaries"     => binaries,
          "post_install" => ["chmod +x #{binaries.join(" ")}"],
        },
        "platform" => {
          Kit::OS.platform.to_name => {
            "link"    => uri,
            "version" => version,
            "sha256"  => sha256,
            "filter"  => filter,
          },
        },
      },
    },
  }.to_json

  by_config(Config::Core.from_yaml(config))
end

case {config, install, destination, binaries, help}
when {String, _, _, _, _}
  by_config(config)
when {_, String, String, Nil, _}
  # Allow shorthand that skips specifying binaries for simple cases
  binaries = [URI.parse(install.to_s).path.split("/").last.strip("/")]
  individual_install(install, destination, binaries, version, sha256, filter)
when {_, String, String, Array(String), _}
  individual_install(install, destination, binaries, version, sha256, filter)
else
  if help
    exit(1)
  else
    puts o
  end
end
