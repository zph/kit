require "yaml"
require "file_utils"

module Kit
  class Config
    include YAML::Serializable

    @[YAML::Field(key: "version")]
    property version : String

    @[YAML::Field(key: "defaults")]
    property defaults : Hash(String, String)?

    @[YAML::Field(key: "binaries")]
    property binaries : Hash(String, Binary)

    class General
      include YAML::Serializable

      @[YAML::Field(key: "binaries")]
      property binaries : Array(String)

      @[YAML::Field(key: "post_install")]
      property post_install : Array(String)?
      getter(post_install) { ["chmod +x #{binaries.join(", ")}"] }

      @[YAML::Field(key: "output")]
      property output : String = FileUtils.pwd

      def output
        File.expand_path(@output.to_s)
      end

      @[YAML::Field(key: "version_cmd")]
      property version_cmd : String? = "--version"

      def primary
        File.expand_path([output, File.basename(binaries.first.to_s)].join("/"))
      end
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
      property filter : String? = ".*"
    end

    class Binary
      include YAML::Serializable

      @[YAML::Field(key: "general")]
      property general : General

      @[YAML::Field(key: "platform")]
      property platform : Hash(String, Platform)
    end
  end
end
