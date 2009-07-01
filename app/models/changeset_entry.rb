class ChangesetEntry < Struct.new(:operation, :file)
  def to_s
    "  #{operation} #{file}"
  end
end
