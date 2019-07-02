module Kit
  class OS
    enum Platform
      Darwin
      Linux
      Unknown

      def to_name
        "#{self}".downcase
      end

      def to_regex
        case self
        when Darwin
          /#{to_name}|osx/
        else
          /#{to_name}/
        end
      end
    end

    enum Architecture
      X32
      X64
      Unknown

      def to_name
        "#{self}".gsub(/[^\d]/, "")
      end
    end

    def self.platform
      stdout, stderr, process = Kit::POpen.call("uname", ["-a"])
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

    def self.arch : Architecture
      stdout, stderr, process = Kit::POpen.call("uname", ["-m"])
      platform = stdout.to_s.downcase.chomp
      case platform
      when "x86_64"
        Architecture::X64
      when /i[3-6]86/
        Architecture::X32
      else
        Architecture::Unknown
      end
    end
  end
end
