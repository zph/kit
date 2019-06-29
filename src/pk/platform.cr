module PK
  class OS
    enum Platform
      Darwin
      Linux
      Unknown

      def to_name
        "#{self}".downcase
      end
    end

    enum Architecture
      X32
      X64
      Unknown
    end

    def self.platform
      stdout, stderr, process = PK::POpen.call("uname", ["-a"])
      platform = stdout.to_s.downcase.split(" ").first
      case platform
      when "darwin"
        Platform::Darwin
      when "linux"
        Platform::Linux
      else
        Platform::Unknown
      end
    end

    def self.arch
      stdout, stderr, process = PK::POpen.call("uname", ["-m"])
      platform = stdout.to_s.downcase.chomp
      case platform
      when "x86_64"
        Architecture::X64
      when /i[3-6]86/,
           Architecture::X32
      else
        Architecture::Unknown
      end
    end
  end
end
