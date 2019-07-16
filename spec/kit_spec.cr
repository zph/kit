require "./spec_helper"

Mocks.create_mock Kit::OS do
  mock self.platform
end

describe Kit do
  describe Kit::Adapters::Github::API do
    it "filters down to one result when multiple architectures are present" do
      allow(Kit::OS).to receive(self.platform).and_return(Kit::OS::Platform::Linux)

      client = Kit::Adapters::Github::API.new("", "")
      result = client.filter_links(["https://github.com/stedolan/jq/releases/download/jq-1.6/jq-darwin64", "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux32", "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"], ".*")
      result.should match(/64$/)
      result.should match(/linux/)
    end
    it "finds the download url for latest" do
      WebMock.stub(:get, "https://api.github.com/repos/octocat/Hello-World/releases/latest")
        .to_return(body: %<{
  "url": "https://api.github.com/repos/octocat/Hello-World/releases/1",
  "html_url": "https://github.com/octocat/Hello-World/releases/v1.0.0",
  "assets_url": "https://api.github.com/repos/octocat/Hello-World/releases/1/assets",
  "upload_url": "https://uploads.github.com/repos/octocat/Hello-World/releases/1/assets{?name,label}",
  "tarball_url": "https://api.github.com/repos/octocat/Hello-World/tarball/v1.0.0",
  "zipball_url": "https://api.github.com/repos/octocat/Hello-World/zipball/v1.0.0",
  "id": 1,
  "node_id": "MDc6UmVsZWFzZTE=",
  "tag_name": "v1.0.0",
  "target_commitish": "master",
  "name": "v1.0.0",
  "body": "Description of the release",
  "draft": false,
  "prerelease": false,
  "created_at": "2013-02-27T19:35:32Z",
  "published_at": "2013-02-27T19:35:32Z",
  "author": {
    "login": "octocat",
    "id": 1,
    "node_id": "MDQ6VXNlcjE=",
    "avatar_url": "https://github.com/images/error/octocat_happy.gif",
    "gravatar_id": "",
    "url": "https://api.github.com/users/octocat",
    "html_url": "https://github.com/octocat",
    "followers_url": "https://api.github.com/users/octocat/followers",
    "following_url": "https://api.github.com/users/octocat/following{/other_user}",
    "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
    "organizations_url": "https://api.github.com/users/octocat/orgs",
    "repos_url": "https://api.github.com/users/octocat/repos",
    "events_url": "https://api.github.com/users/octocat/events{/privacy}",
    "received_events_url": "https://api.github.com/users/octocat/received_events",
    "type": "User",
    "site_admin": false
  },
  "assets": [
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/releases/assets/1",
      "browser_download_url": "https://github.com/octocat/Hello-World/releases/download/v1.0.0/example.zip",
      "id": 1,
      "node_id": "MDEyOlJlbGVhc2VBc3NldDE=",
      "name": "example.zip",
      "label": "short description",
      "state": "uploaded",
      "content_type": "application/zip",
      "size": 1024,
      "download_count": 42,
      "created_at": "2013-02-27T19:35:32Z",
      "updated_at": "2013-02-27T19:35:32Z",
      "uploader": {
        "login": "octocat",
        "id": 1,
        "node_id": "MDQ6VXNlcjE=",
        "avatar_url": "https://github.com/images/error/octocat_happy.gif",
        "gravatar_id": "",
        "url": "https://api.github.com/users/octocat",
        "html_url": "https://github.com/octocat",
        "followers_url": "https://api.github.com/users/octocat/followers",
        "following_url": "https://api.github.com/users/octocat/following{/other_user}",
        "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
        "organizations_url": "https://api.github.com/users/octocat/orgs",
        "repos_url": "https://api.github.com/users/octocat/repos",
        "events_url": "https://api.github.com/users/octocat/events{/privacy}",
        "received_events_url": "https://api.github.com/users/octocat/received_events",
        "type": "User",
        "site_admin": false
      }
    }
  ]
}>)

      client = Kit::Adapters::Github::API.new("octocat", "Hello-World")
      links = client.asset_urls_by_release_tag_name(nil)
      links.should eq(["https://github.com/octocat/Hello-World/releases/download/v1.0.0/example.zip"])
      client.filter_links(links, ".*").should eq(links.first)
    end
  end

  describe URI do
    gh = "github"
    tag = "v0.3.0"
    repo = "zph/moresql"

    it "defaults fragment to latest" do
      Kit::URI.new("github://#{repo}").latest?.should eq(true)
    end

    it "handles long form of github urls" do
      Kit::URI.new("github://#{repo}#v0.3.0").uri.scheme.should eq(gh)
      Kit::URI.new("github://#{repo}#v0.3.0").uri.fragment.should eq(tag)
    end

    it "handles short form of github urls" do
      Kit::URI.new("#{repo}#v0.3.0").uri.scheme.should eq(gh)
      Kit::URI.new("#{repo}#v0.3.0").uri.fragment.should eq(tag)
    end

    defaults_yaml = Kit::Config.from_yaml(IO::Memory.new(%q{
---
version: v1
binaries:
  jq:
    general:
      output: data
      binaries:
      - jq
    platform:
      darwin:
        link: github://stedolan/jq#jq-1.6
        version: jq-1.6
        sha256: 5c0a0a3ea600f302ee458b30317425dd9632d1ad8882259fcaf4e9b868b2b1ef
      }))

    it "sets defaults in YAML config for version_cmd" do
      defaults_yaml.binaries["jq"].general.version_cmd.should eq("--version")
    end

    it "sets the default filter value for config" do
      defaults_yaml.binaries["jq"].platform["darwin"].filter.should eq(".*")
    end

    it "uses full path for output field" do
      defaults_yaml.binaries["jq"].general.output.should match(/kit\/data$/)
    end

    it "sets default post_install hook" do
      defaults_yaml.binaries["jq"].general.post_install.should eq(["chmod +x jq"])
    end

    it "parses filename to extract extension" do
      Kit::Filetype.extension("foo.tar.bz2").should eq("tar.bz2")
    end

    it "parses filename to extract extension zip" do
      Kit::Filetype.extension("foo.zip").should eq("zip")
    end

    it "parses paths with decimals correctly for filetype" do
      link = "chamber-v2.3.3-darwin-amd64"
      Kit::Filetype.extension(link).should eq(nil)
    end

    it "parses paths with decimals correctly for filetype with real extension" do
      link = "chamber-v2.3.3-darwin-amd64.tar.gz"
      Kit::Filetype.extension(link).should eq("tar.gz")
    end

    it "parses paths with decimals correctly for filetype with alternate ordering" do
      link = "chamber-darwin-amd64-v2.3.3.tar.gz"
      Kit::Filetype.extension(link).should eq("tar.gz")
    end

    it "parses paths with decimals correctly for filetype with semvar without v" do
      link = "chamber-darwin-amd64-2.3.3.tar.gz"
      Kit::Filetype.extension(link).should eq("tar.gz")
    end
  end
end
