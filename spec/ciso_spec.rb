require_relative '../lib/ciso.rb'

describe CISO do
  describe "decompression" do
    subject { CISO::Inflate.new('./spec/fixtures/memtest.ciso') }

    before do
      subject.inflate
    end

    it "can decompress an iso" do
      expect(subject).to be_decompressed
    end
  end

  describe "compression" do
    subject { CISO::Deflate.new('./spec/fixtures/memtest.iso') }

    before do
      subject.deflate
    end

    it "can compress an iso" do
      expect(subject).to be_compressed
    end
  end
end
