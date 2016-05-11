# shared_including_spec
require File.expand_path('../shared', __FILE__)

RSpec.describe "A spec" do
  context "a context" do
    #The line where it is included:
    include_examples "shared specs", Array
  end
end

