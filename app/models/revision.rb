Revision = Struct.new :number, :committed_by, :time, :message, :changeset

class Revision
  def to_s
    "Revision #{number} committed by #{committed_by} on #{time.strftime('%Y-%m-%d %H:%M:%S')}\n" +
    message +
    "\n" +
    changeset.collect { |entry| entry.to_s }.join("\n") +
    "\n"
  end
  
  def to_i
    number.to_i
  end

end