module Kit
  class Versioning
    getter binary
    getter file
    getter path

    def initialize(@binary : String)
      @binary = File.expand_path(@binary)
      @file = File.basename(@binary)
      @path = File.dirname(@binary)
    end

    def get(flag)
      return unless File.exists?(binary) && File.executable?(binary)
      LOG.debug("primary file location") { [path, file, flag].join(" ") }
      stdout, stderr, process = POpen.call(binary, [flag])
      version_string = [stdout.to_s, stderr.to_s].join(" ").strip
    end

    def get_all(flags : Array(String))
      flags.each_with_object({} of String => String?) do |f, acc|
        acc[f] = get(f)
      end
    end

    def get?(flag)
      !!get(flag)
    end

    def match?(version, output)
      Regex.new(".*(#{Regex.escape(version)}).*").match(output.to_s)
    end

    def match_any?(flags, version)
      flags.any? { |flag| match?(version, get(flag)) }
    end
  end
end
