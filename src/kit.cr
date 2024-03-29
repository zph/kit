require "http/client"
require "file_utils"
require "tempdir"
require "logger"
require "yaml"
require "openssl"
require "halite"

require "./kit/**"

LOG_LEVEL = Logger::Severity.parse((ENV["LOG_LEVEL"]? || "info").to_s)
LOG       = Logger.new(STDOUT, level: LOG_LEVEL)

module Kit
end
