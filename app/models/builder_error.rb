class BuilderError < RuntimeError
  attr_reader :status

  def initialize(message, status = "error")
    super message
    @status = status
  end
end