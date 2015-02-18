require 'zlib'

module CISO
  class Deflate
    CISO_MAGIC = 0x4F534943 # CISO
    CISO_HEADER_SIZE = 0x18 # 24
    CISO_BLOCK_SIZE = 0x800 # 2048
    CISO_HEADER_FMT = '<LLQLCCxx'
    CISO_WBITS = -15 # Maximum window size, suppress gzip header check.
    CISO_PLAIN_BLOCK = 0x80000000

    def initialize(input_file_path, output_file_path=StringIO.new)
      @input_file_path  = input_file_path
      @output_file_path = output_file_path
    end

    def inspect
      "<CISO::Deflate #{object_id.to_s(16)}>"
    end

    def deflate
#CISO\x18\x00\x00\x00\x00\x10\x1c\x00\x00\x00\x00\x00\x00\x08\x00\x00\x01\x00\x00\x00
#CISO\x18\x00\x00\x00\x00\x10\x1C\x00\x00\x00\x00\x00\x00\b\x00\x00\x01\x00\x00\x00
      output_file.write ciso_header
      output_file.write block_index.pack('<I*')

      (0...total_uncompressed_blocks).each do |raw_block|
        block_index[raw_block] = output_file.pos
        raw_data = input_file.read(CISO_BLOCK_SIZE)
        raw_data_size = raw_data.length

        z = Zlib::Deflate.new(Zlib::BEST_SPEED)
        compressed_data = z.deflate(raw_data)[2..-1]
        compressed_data_size = compressed_data.size
        z.close

        if compressed_data_size >= raw_data_size
          block_index[raw_block] |= CISO_PLAIN_BLOCK
          output_file.write(raw_data)
        else
          output_file.write(compressed_data)
        end
      end

      output_file.seek(CISO_HEADER_SIZE)
      output_file.write(block_index.pack('<I*'))
      @compressed = true
    end
 
    def compressed?
      @compressed
    end

    private

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

    def output_file
      @output_file ||= if @output_file_path.is_a?(StringIO) # For testing
        @output_file_path
      else
        File.open(@output_file_path, 'wb')
      end
    end

    def total_uncompressed_blocks
      total_uncompressed_size / CISO_BLOCK_SIZE
    end

    def input_file
      @input_file ||= File.open(@input_file_path, 'rb')
    end
  end
end
