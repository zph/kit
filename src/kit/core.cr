# TODO:
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

    def self.write(content, sha256, filename, output_folder, binaries)
      dir = TempDir.new "kit"
      tmpfile = [dir.to_s, filename].join("/")
      LOG.info("tmpfile") { tmpfile }
      File.write(tmpfile, content)

      compare_digest(content, sha256)

      extname = Filetype.extension(filename)

      if !Dir.exists?(output_folder)
        LOG.info("creating missing directory") { output_folder }
        FileUtils.mkdir_p(output_folder)
      end

      LOG.debug("filename") { filename }
      type = Filetype.type?(filename)
      case
      when type
        type.new(binaries, dir.to_s, output_folder).process(tmpfile)
      else
        LOG.warn("Unable to identify extension type assuming binary")
        Filetype::Binary.new(binaries, dir.to_s, output_folder).process(tmpfile)
      end
    end
  end
end
