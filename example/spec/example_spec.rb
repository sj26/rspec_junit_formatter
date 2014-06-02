require "spec_helper"

describe "some example specs" do
  it "should succeed" do
    expect(true).to be_truthy
  end

  it "should fail" do
    expect(false).to be_truthy
  end

  it "should raise" do
    raise ArgumentError
  end

  it "should be pending" do
    skip
  end
end
