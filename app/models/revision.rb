class Revision
  include Comparable

  attr_reader :number, :committed_by, :time, :message, :changeset 

  def initialize(number, committed_by = nil, time = nil, message = nil, changeset = nil)
    @number = number.to_i
    @committed_by, @time, @message, @changeset = committed_by, time, message, changeset
  end

  def to_s
    <<-EOL
Revision #{number} committed by #{committed_by} on #{time.strftime('%Y-%m-%d %H:%M:%S') if time}
#{message}
#{changeset ? changeset.collect { |entry| entry.to_s }.join("\n") : nil}
    EOL
  end

  def <=>(other)
    raise("Comparing a revision to #{other.class} is not supported") unless other.is_a? Revision
    @number <=> other.number
  end

  def to_i
    @number
  end
end
