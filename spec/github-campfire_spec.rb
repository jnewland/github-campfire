require File.dirname(__FILE__) + '/spec_helper'

describe GithubCampfire, "process_payload" do
  before do
    @ghcf = GithubCampfire.new
    ghcf.stub!(:connect)
  end
  
  def fixture(name)
    File.read(File.dirname(__FILE__) + "/fixtures/#{name}.json")
  end
  
  attr_reader :ghcf
  
  describe "processing commits" do
    before do
      class <<ghcf
        def process_commit(c)
          processed_commits << c['message']
        end
        
        def processed_commits
          @processed_commits ||= []
        end
      end
    end
    
    # github.com before 7/30/2008
    describe "called with a Hash of commits" do
      before do
        @payload = fixture(:github_commits_hash)
      end
      
      it "processes each commit in order of timestamp" do
        ghcf.process_payload(@payload)
        ghcf.processed_commits.should == ["update pricing a tad", "okay i give in"]
      end
    end
    
    # github.com after 7/30/2008
    describe "called with an Array of commits" do
      before do
        @payload = fixture(:github_commits_array)
      end
      
      it "processes each commit in order of timestamp" do
        ghcf.process_payload(@payload)
        ghcf.processed_commits.should == ["update pricing a tad", "okay i give in"]
      end
    end
  end
end
