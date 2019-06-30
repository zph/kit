require "json"
require "uri"

module Kit
  module Github
    class API
      ENDPOINT = "https://api.github.com"

      def initialize(@org : String, @repo : String)
      end

      def asset_urls_by_release_tag_name(tag_name)
        response = HTTP::Client.get("#{ENDPOINT}/repos/#{@org}/#{@repo}/releases/tags/#{tag_name}")
        # TODO: handle bad responses
        h = JSON.parse(response.body.to_s).as_h
        h["assets"].as_a.map { |r| r["browser_download_url"].to_s }
      end

      def download_link(tag_name : String, filter)
        urls = asset_urls_by_release_tag_name(tag_name)
        matches = urls.grep(OS.platform.to_regex).grep(/#{filter}/)
        LOG.info("matches") { matches }
        if matches.size == 1
          matches.first
        else
          # TODO: consider how to do this for platform, but right now we're ignoring 86x systems and hoping for 64
          matches.reject { |m| m[/sha\d+/] }
            .grep(/tar/)
            .grep(/64/).first
        end
      end
    end
  end
end
