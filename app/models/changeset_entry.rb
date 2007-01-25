ChangesetEntry = Struct.new :operation, :file
class ChangesetEntry
  def to_s
    "  #{operation} #{file}"
  end
end
