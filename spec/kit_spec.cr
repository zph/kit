require "./spec_helper"

Mocks.create_mock Kit::OS do
  mock self.platform
end

describe Kit do
  describe Kit::Github::API do
    it "filters down to one result when multiple architectures are present" do
      allow(Kit::OS).to receive(self.platform).and_return(Kit::OS::Platform::Linux)

      client = Kit::Github::API.new("", "")
      result = client.filter_links(["https://github.com/stedolan/jq/releases/download/jq-1.6/jq-darwin64", "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux32", "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"], ".*")
      result.should match(/64$/)
      result.should match(/linux/)
    end
  end
  describe URI do
    it "defaults fragment to latest" do
      Kit::URI.new("zph/moresql#v0.3.0").uri.scheme.should eq("github")
      Kit::URI.new("github://zph/moresql#v0.3.0").uri.scheme.should eq("github")
      Kit::URI.new("github://zph/moresql").uri.fragment.should eq("latest")
    end
  end
  it "works" do
    true.should eq(true)
  end
end
