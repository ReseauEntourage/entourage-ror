module OpenaiServices
  class CodeChunker
    CHUNK_LINES = 250
    OVERLAP = 40

    FILE_PATTERNS = [
      "app/**/*.rb",
      "config/**/*.rb",
      "lib/**/*.rb",
      "db/schema.rb",
      "db/migrate/**/*.rb",
      "docs/**/*"
    ]

    def self.collect_chunks
      chunks = []

      FILE_PATTERNS.each do |pattern|
        Dir.glob(Rails.root.join(pattern)).each do |filepath|
          next unless File.file?(filepath)

          lines = File.read(filepath).lines
          start = 0

          while start < lines.size
            stop = start + CHUNK_LINES
            slice = lines[start...stop]
            break if slice.blank?

            chunks << {
              filepath: filepath.sub("#{Rails.root}/", ""),
              start_line: start + 1,
              end_line: [stop, lines.size].min,
              content: slice.join
            }

            start += (CHUNK_LINES - OVERLAP)
          end
        end
      end

      chunks
    end
  end
end
