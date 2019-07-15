# TODO:
# - Add tar.bz2 handling (various based on extension)
# - Add callbacks - bash hooks with ENV setup (KIT_BINARY, KIT_BINARIES, KIT_*) so it can operate on the variables from here when called through Process
module Kit
  class URI
    def initialize(@link : String)
      @uri = ::URI.parse(@link)

      if @uri.scheme.nil?
        @uri = ::URI.parse("github://" + link)
      end
    end

    def uri
      @uri
    end

    def latest?
      @uri.fragment.nil?
    end
  end

  module Core
    def self.resolve_link(link, filter = ".*") : String
      uri = Kit::URI.new(link).uri
      scheme, host, path, fragment = uri.scheme, uri.host, uri.path.strip("/"), uri.fragment
      case {scheme, host, path, fragment}
      when {"github", String, String, String?}
        client = Adapters::Github::API.new(host, path)
        client.download_link(fragment, filter)
      when {"github", _, _, _}
        raise("Invalid github uri format #{link}")
      when {/^https?$/, String, String, String}
        link
      when {"file", String, String, _}
        link
      else
        link
      end
    end

    def self.get(link)
      uri = ::URI.parse(link)
      case uri.scheme
      when "https", "http"
        get_http(link).body
      when "file"
        # "file://~/tmp/kit/bin/jq"
        File.read(link.split("//", 2).last)
      end
    end

    def self.get_http(link)
      loop do
        response = HTTP::Client.get(link)
        LOG.info("status_code") { response.status_code }
        case response.status_code
        when 302
          link = response.headers["Location"]
        when 200
          return response
          break
        else
        end
      end
    end

    class Binary
      def self.copy(src, folder, file)
        output = [folder, file].join("/")
        LOG.info("output, src") { [output, src] }
        FileUtils.cp(src, File.expand_path(output))
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
        def initialize(@binaries : Array(String), @dir : String, @outputname : String)
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
            match = Dir.glob("#{@dir}/{**/#{bin},#{bin}}").uniq
              .tap { |m| LOG.debug("glob_matches") { m } }
              .select do |m|
                # Pin exact file binary name match
                File.basename(m) == bin &&
                  File.file?(m)
              end
            LOG.debug("glob") { match }

            if match && match.size == 1
              Binary.copy(match.first, @outputname, bin)
            else
              raise("Unable to find binary too many matching names #{match}")
            end
          end
        end

        def process(tmpfile)
          extract(tmpfile, @dir)
          process_archive
        end
      end
    end

    def self.compare_digest(body, sha256 : Nil)
      LOG.info("digest") { "Not provided, skipping verification" }
      digest = OpenSSL::Digest.new("sha256").update(body).hexdigest
      LOG.info("downloaded digest") { digest }
    end

    def self.compare_digest(body, sha256 : String)
      digest = OpenSSL::Digest.new("sha256").update(body).hexdigest
      LOG.info("sha256") { digest }
      if !(digest == sha256)
        LOG.error("digest comparison failed")
        LOG.info("digest (sha256) comparison (expected vs actual)") { [sha256, digest].join(" <-> ") }
        exit(1)
      else
        LOG.info("sha comparison") { "success" }
      end
    end

    def self.write(content, sha256, filename, outputname, binaries)
      dir = TempDir.new "kit"
      tmpfile = [dir.to_s, filename].join("/")
      LOG.info("tmpfile") { tmpfile }
      File.write(tmpfile, content)

      compare_digest(content, sha256)

      # Builtin extname parses in way that's not helpful to us (.gz, instead of full .tar.gz)
      # Remove fragment in case its present
      extname = filename.split("#").first.split(".", 2).last.downcase

      FileUtils.mkdir_p(outputname)
      LOG.debug("filename") { filename }
      case
      when Archive::Targz.match?(filename)
        Archive::Targz.new(binaries, dir.to_s, outputname).process(tmpfile)
      when extname.match(/(zip|tar\.bz2?|xz)/)
        raise "Unhandled extension type #{extname}"
      else
        Binary.copy(tmpfile, outputname, binaries.first)
      end
    end
  end
end
