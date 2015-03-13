require 'zlib'

module CISO
  CISO_MAGIC       = 0x4F534943 # CISO
  CISO_HEADER_SIZE = 0x18 # 24
  CISO_BLOCK_SIZE  = 0x800 # 2048
  CISO_HEADER_FMT  = '<LLQLCCxx'
  CISO_WBITS       = -15 # Maximum window size, suppress gzip header check.
  CISO_PLAIN_BLOCK = 0x80000000

  module Helpers
    def output_file
      @output_file ||= if @output_file_path.is_a?(StringIO) # For testing
        @output_file_path
      else
        File.open(@output_file_path, 'wb')
      end
    end

    def input_file
      @input_file ||= File.open(@input_file_path, 'rb')
    end

    def plain_block?(block)
      block & CISO_PLAIN_BLOCK != 0
    end
  end

  class Inflate
    include Helpers

    attr_reader :block_index

    def initialize(input_file_path, output_file_path=StringIO.new)
      @input_file_path  = input_file_path
      @output_file_path = output_file_path
    end

    def inspect
      "<CISO::Inflate #{object_id.to_s(16)}>"
    end

    def inflate
      parse_block_index

      (0...total_uncompressed_blocks).each_with_index do |block, i|
        decompress_block(block, i)
      end

      @decompressed = true
    end

    def decompressed?
      @decompressed
    end

    private

    def decompress_block(block, index)
      if plain_block?(block_index[index])
        data = input_file.read(CISO_BLOCK_SIZE)
        output_file.write(data) #uncompressed already
      else
        current_block = block_index[index]
        next_block    = block_index[index+1]# & 0x7FFFFFFF
        read_size = if next_block
          next_block - current_block
        end

        input_file.seek(current_block)
        data = input_file.read(read_size)
        z = Zlib::Inflate.new(CISO_WBITS)
        output_file.write(z.inflate(data))
      end
    end

    def total_uncompressed_blocks
      total_uncompressed_size / CISO_BLOCK_SIZE
    end

    def parse_block_index
      return @block_index if @block_index

      @block_index = []
      input_file.rewind
      data = input_file.seek(CISO_HEADER_SIZE)
      total_blocks.times do |i|
        @block_index.push input_file.read(4).unpack("<I")[0]
      end

      @block_index
    end

    def total_blocks
      total_uncompressed_size / CISO_BLOCK_SIZE
    end

    def total_uncompressed_size
      return @total_uncompressed_size if @total_uncompressed_size

      input_file.rewind
      data = input_file.read(CISO_HEADER_SIZE)
			ciso_header = data.unpack(CISO_HEADER_FMT)
      @total_uncompressed_size = ciso_header[2]
    end
  end

  class Deflate
    include Helpers

    attr_reader :input_file_path, :output_file_path

    def initialize(input_file_path, output_file_path=StringIO.new)
      @input_file_path  = input_file_path
      @output_file_path = output_file_path
    end

    def inspect
      "<CISO::Deflate #{object_id.to_s(16)}>"
    end

    def deflate
      output_file.write ciso_header
      output_file.write block_index.pack('<I*')

      (0...total_uncompressed_blocks).each_with_index do |raw_block, i|
        compress_block(raw_block)
      end

      output_file.seek(CISO_HEADER_SIZE)
      output_file.write(block_index.pack('<I*'))
      @compressed = true
    end
 
    def compressed?
      @compressed
    end

    private

    def compress_block(raw_block)
      block_index[raw_block] = output_file.pos
      raw_data = input_file.read(CISO_BLOCK_SIZE)
      raw_data_size = raw_data.length

      z = Zlib::Deflate.new(6, CISO_WBITS) # 6 is compression level
      compressed_data = StringIO.new
      compressed_data << z.deflate(raw_data, Zlib::FINISH)
      compressed_data_size = compressed_data.size

      if compressed_data_size >= raw_data_size
        block_index[raw_block] |= CISO_PLAIN_BLOCK
        output_file.write(raw_data)
      else
        compressed_data.rewind
        output_file.write(compressed_data.read)
      end
      z.close
    end

    def block_index
      @block_index ||= ([0x00] * (total_uncompressed_blocks + 1))
    end

    def ciso_header
      [ CISO_MAGIC,
        CISO_HEADER_SIZE,
        total_uncompressed_size,
        CISO_BLOCK_SIZE,
        1, #version
        0  #align
      ].pack(CISO_HEADER_FMT)
    end

    def total_uncompressed_size
      File.size(@input_file_path)
    end

    def total_uncompressed_blocks
      total_uncompressed_size / CISO_BLOCK_SIZE
    end
  end
end
