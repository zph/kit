require "json"
require "uri"

module Kit
  module Adapters
    module Github
      class API
        ENDPOINT = "https://api.github.com"

        def initialize(@org : String, @repo : String)
        end

        def get(route)
          response = Halite.get([ENDPOINT, "/", route.join("/")].join)
          response.parse("json").as_h
        end

        def self.search(query)
          response = new("", "").get(["search", "repositories?q=#{query}"])
        end

        def extract_download_urls(json)
          json["assets"].as_a.map { |r| r["browser_download_url"].to_s }
        end

        def asset_urls_by_release_tag_name(tag : Nil)
          h = get(["repos", @org, @repo, "releases", "latest"])
          extract_download_urls(h)
        end

        def asset_urls_by_release_tag_name(tag_name)
          h = get(["repos", @org, @repo, "releases", "tags", tag_name])
          extract_download_urls(h)
        end

        def download_link(tag_name : String | Nil, filter)
          urls = asset_urls_by_release_tag_name(tag_name)
          filter_links(urls, filter)
        end

        def filter_links(links : Array(String), filter) : String
          LOG.debug("links") { links }
          matches = links.each_with_object(Hash(String, Int32).new(0)) do |link, acc|
            [{3, /#{filter}/},
             {5, OS.platform.to_regex},
             {2, /#{OS.arch.to_name}/i},
             {1, /(gz|bz2)$/i},
            ].each do |count, r|
              acc[link] += if is_match(link, r)
                             count
                           else
                             0
                           end
            end

            acc[link] -= if is_match(link, /sha\d+/i)
                           1
                         else
                           0
                         end
          end.map { |k, v| [k, v] }.sort_by! { |x| x[1].to_i }.reverse
          LOG.debug("matches") { matches }
          if matches.size == 0
            raise("No matches found from #{links}")
          else
            matches.first[0]?.to_s
          end
        end

        EMPTY = [] of Int32

        def is_match(link, regex : Regex) : Bool
          (link.match(regex) || EMPTY).size > 0
        end
      end
    end
  end
end
