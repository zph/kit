# TODO:
# - Add tar.bz2 handling (various based on extension)
# - Add callbacks - bash hooks with ENV setup so it can operate on the variables from here when called through Process
# - Use link: github://ORG/REPO/RELEASE_NAME syntax + this
# ---- curl https://api.github.com/repos/stedolan/jq/releases/tags/jq-1.6 | jq '.assets[] | .browser_download_url'
# ---- and judicious use of Regexes to guess the right things to install
module Kit
  module Core
    def self.get(link)
      uri = URI.parse(link)
      host = uri.host
      path = uri.path
      fragment = uri.fragment
      if host && path && fragment
        download_link = case uri.scheme
                        when "github"
                          # Parse url github://stedolan/jq@jq-1.6
                          # Github::API.new()
                          client = Github::API.new(host, path.strip("/"))
                          client.download_link(fragment)
                        when /^https?$/
                          link
                        else
                          link
                        end
        get_http(download_link)
      end
    end

    def self.get_http(link)
      loop do
        response = HTTP::Client.get(link)
        LOG.info("status_code") { response.status_code }
        case
        when response.status_code == 302
          link = response.headers["Location"]
        when response.status_code == 200
          return response
          break
        else
        end
      end
    end


    class Binary
      def self.copy(src, folder, file)
        output = [folder, file].join("/")
        LOG.debug("output") { output }
        FileUtils.cp(src, output)
        File.expand_path(output)
      end
    end

    module Archive
      abstract class Base
        abstract def process(tmpfile : String)
      end

      #       class Tarbz < Base
      #         def initialize(@binaries, @dir, @outputname)
      #         end

      #         def self.extensions
      #           [/tar\.bz$/, /tar\.bz2$/]
      #         end

      #         def self.match?(filename)
      #           extensions.find { |e| e.match(filename) }
      #         end

      #         def process(tmpfile)
      #         end
      #       end

      class Targz < Base
        def initialize(@binaries : Array(YAML::Any), @dir : String, @outputname : String)
        end

        def self.extensions
          [/tar\.gz$/, /tgz$/]
        end

        def self.match?(filename)
          extensions.find { |e| e.match(filename) }
        end

        def extract(tmpfile, dir)
          stdout, stderr, process = POpen.call("tar", ["-xvf", tmpfile, "-C", dir])
          LOG.debug("output") { [stdout.to_s, stderr.to_s, process] }
          [stdout, stderr, process]
        end

        def process_archive
          @binaries.to_a.map do |bin|
            match = Dir.glob("#{@dir}/**/#{bin}").tap { |m| LOG.info(m) }.select { |m| File.file?(m) && File.executable?(m) }.first
            LOG.debug("glob") { match }

            if match
              Binary.copy(match, @outputname, bin)
            else
              LOG.error("Unable to find binary")
              exit(1)
            end
          end
        end

        def process(tmpfile)
          extract(tmpfile, @dir)
          process_archive
        end
      end
    end

    def self.write(response, sha256, filename, outputname, binaries)
      dir = TempDir.new "kit"
      tmpfile = [dir.to_s, filename].join("/")
      LOG.info("tmpfile") { tmpfile }
      File.write(tmpfile, response.body)
      digest = OpenSSL::Digest.new("sha256").update(response.body).hexdigest
      LOG.info("sha256") { digest }
      if !(digest == sha256)
        LOG.error("digest comparison failed")
        LOG.info("digest (sha256) comparison (expected vs actual)") { [sha256, digest].join(" <-> ") }
        exit(1)
      else
        LOG.info("sha comparison") { "success" }
      end

      # extname = File.extname(filename).downcase
      extname = filename.split(".", 2).last.downcase
      # Handle TAR GZ
      FileUtils.mkdir_p(outputname)
      LOG.info("extname") { extname }
      case
      when Archive::Targz.match?(filename)
        Archive::Targz.new(binaries, dir.to_s, outputname).process(tmpfile)
      else
        Binary.copy(tmpfile, outputname, binaries.first)
      end
    end
  end
end
