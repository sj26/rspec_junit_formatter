require "spec_helper"

describe "some example specs" do
  it "should succeed" do
    true.should be_true
  end

  it "should fail" do
    false.should be_true
  end

  it "should raise" do
    raise ArgumentError
  end

  it "should be pending" do
    pending
  end
end
