# example_shared.rb

RSpec.shared_examples "shared specs" do |collection_class|
  it "does not pass" do
    expect(1).to eq(2)
  end
end

