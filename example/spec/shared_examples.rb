shared_examples "shared examples" do
  context "in a shared example" do
    it "succeeds" do
      expect(true).to be(true)
    end

    it "also fails" do
      expect(false).to be(true)
    end
  end
end
