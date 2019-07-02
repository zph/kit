require "json"
require "uri"

module Kit
  module Github
    class API
      ENDPOINT = "https://api.github.com"

      def initialize(@org : String, @repo : String)
      end

      def asset_urls_by_release_tag_name(tag : Nil)
        response = HTTP::Client.get("#{ENDPOINT}/repos/#{@org}/#{@repo}/releases/latest")
        if response.success?
          h = JSON.parse(response.body.to_s).as_h
          h["assets"].as_a.map { |r| r["browser_download_url"].to_s }
        else
          raise("Failure to fetch API response for #{@org}/#{@repo} #{response}")
        end
      end

      def asset_urls_by_release_tag_name(tag_name)
        response = HTTP::Client.get("#{ENDPOINT}/repos/#{@org}/#{@repo}/releases/tags/#{tag_name}")
        if response.success?
          h = JSON.parse(response.body.to_s).as_h
          h["assets"].as_a.map { |r| r["browser_download_url"].to_s }
        else
          raise("Failure to fetch API response for #{tag_name} #{response}")
        end
      end

      def download_link(tag_name : String | Nil, filter)
        urls = asset_urls_by_release_tag_name(tag_name)
        filter_links(urls, filter)
      end

      def filter_links(links : Array(String), filter) : String
        matches = links.each_with_object(Hash(String, Int32).new(0)) do |link, acc|
          [/#{filter}/,
           OS.platform.to_regex,
           /#{OS.arch.to_name}/i,
           /(gz|bz2)$/i,
          ].each do |r|
            acc[link] += is_match(link, r)
          end

          acc[link] -= is_match(link, /sha\d+/i)
        end.map { |k, v| [k, v] }.sort_by! { |x| x[1].to_i }.reverse
        if matches.size == 0
          raise("No matches found from #{links}")
        else
          matches.first[0]?.to_s
        end
      end

      EMPTY = [] of Int32

      def is_match(link, regex : Regex) : Int32
        (link.match(regex) || EMPTY).size
      end
    end
  end
end
