Revision = Struct.new :number, :committed_by, :time, :message, :changeset

class Revision  
  def to_s
    <<-EOL
Revision #{number} committed by #{committed_by} on #{time.strftime('%Y-%m-%d %H:%M:%S') if time}
#{message}
#{changeset ? changeset.collect { |entry| entry.to_s }.join("\n") : nil}
    EOL
  end

  def ==(other)
    number == other.number
  end
  
  def to_i
    number
  end
end
