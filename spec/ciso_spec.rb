require_relative '../lib/ciso.rb'
require 'open-uri'

describe CISO do
  describe "compression" do
    # TODO Write this out to a file after the first fetch
    subject { CISO::Deflate.new(open('http://www.memtest.org/download/5.01/memtest86+-5.01.iso.gz')) }

    before do
      subject.deflate
    end

    it "can compress an iso" do
      expect(subject).to be_compressed
    end
  end

end
