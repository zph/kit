require "./spec_helper"

describe Kit do
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
