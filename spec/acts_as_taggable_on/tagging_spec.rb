require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsTaggableOn::Tagging do
  before(:each) do
    @tagging = TestTagging.new
  end

  it "should not be valid with a invalid tag" do
    @tagging.taggable = TaggableModel.create(:name => "Bob Jones")
    @tagging.tag = TestTag.new(:name => "")
    @tagging.context = "tags"

    @tagging.should_not be_valid
    
    @tagging.errors[:tag_id].should == ["can't be blank"]
  end

  it "should not create duplicate taggings" do
    @taggable = TaggableModel.create(:name => "Bob Jones")
    @tag = TestTag.create(:name => "awesome")

    lambda {
      2.times { TestTagging.create(:taggable => @taggable, :tag => @tag, :context => 'tags') }
    }.should change(TestTagging, :count).by(1)
  end
end
