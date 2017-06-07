describe "some example specs" do
  it "should succeed" do
    expect(true).to be_true
  end

  it "should fail" do
    expect(false).to be_true
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

  it "can include unicodes 😁" do
    expect("🚀").to eql("🔥")
  end

  it %{escapes <html tags='correctly' and="such &amp; such">} do
    expect("<p>This is important</p>").to eql("<p>This is <strong>very</strong> important</p>")
  end

  it "escapes naughty \0 characters" do
    expect("\0\0\0").to eql("emergency services")
  end

  if instance_methods.include? :be_truthy
    def be_true
      be_truthy
    end
  end
end
