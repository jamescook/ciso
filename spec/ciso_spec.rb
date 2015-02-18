require_relative '../lib/ciso.rb'

describe CISO do
  describe "compression" do

  end

  subject { CISO::Deflate.new(File.expand_path("~/Desktop/memtest86+-5.01.iso")) }

  before do
    subject.deflate
  end

  it "can compress an iso" do
    expect(subject).to be_compressed
  end
end
