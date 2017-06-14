require_relative "shared_examples"

describe "some example specs" do
  it "should succeed" do
    expect(true).to be(true)
  end

  it "should fail" do
    expect(false).to be(true)
  end

  it "should raise" do
    raise ArgumentError
  end

  it "should be pending" do
    if defined? skip
      skip
    else
      pending
    end
  end

  it "omits naughty \0 and \e characters" do
    expect("\0\0\0").to eql("emergency services")
  end

  it "escapes controlling \u{7f} characters" do
    expect("\u{7f}").to eql("pacman om nom nom")
  end

  it "can include unicodes 😁" do
    expect("🚀").to eql("🔥")
  end

  it %{escapes <html tags='correctly' and="such &amp; such">} do
    expect("<p>This is important</p>").to eql("<p>This is <strong>very</strong> important</p>")
  end

  it_should_behave_like "shared examples"
end
