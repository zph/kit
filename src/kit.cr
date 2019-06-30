require "http/client"
require "file_utils"
require "tempdir"
require "logger"
require "yaml"
require "openssl"

require "./kit/**"

LOG = Logger.new(STDOUT, level: Logger::INFO)

module Kit
  VERSION = "0.3.0"
end
