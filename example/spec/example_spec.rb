# frozen_string_literal: true

require "spec_helper"
require_relative "shared_examples"

describe "some example specs" do
  it "succeeds" do
    expect(true).to be(true)
  end

  it "fails" do
    expect(false).to be(true)
  end

  it "raises" do
    raise ArgumentError
  end

  it "is pending" do
    if defined? skip
      skip
    else
      pending
    end
  end

  it "shows diffs cleanly" do
    expect({ a: "b", c: "d" }).to eql({ a: 2, c: 4 })
  end

  it "replaces naughty \0 and \e characters, \x01 and \uFFFF too" do
    expect("\0\0\0").to eql("emergency services")
  end

  it "escapes controlling \u{7f} characters" do
    expect("\u{7f}").to eql("pacman om nom nom")
  end

  it "can include unicodes 😁" do
    expect("🚀").to eql("🔥")
  end

  it %(escapes <html tags='correctly' and="such &amp; such">) do
    expect("<p>This is important</p>").to eql("<p>This is <strong>very</strong> important</p>")
  end

  it_behaves_like "shared examples"

  it "can capture stdout and stderr" do
    $stdout.puts "Test"
    warn "Bar"
  end
end
