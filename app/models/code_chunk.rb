class CodeChunk < ApplicationRecord
  validates :filepath, :start_line, :end_line, :content, presence: true
end
