class FakeSourceControl < SourceControl::AbstractAdapter
  attr_reader :username, :latest_revision
  attr_accessor :path

  def initialize(username = nil)
    @username = username
    @path = "/some/fake/path"
    @latest_revision = nil
  end

  def checkout
    File.open("#{path}/README", "w") {|f| f << "some text"}
  end

  def up_to_date?(reasons)
    true
  end

  def creates_ordered_build_labels?
    true
  end
  
  def add_revision(opts={})
    @latest_revision = FakeRevision.new(opts)
  end
  
  class FakeRevision < SourceControl::AbstractRevision
    attr_reader :message, :number, :time, :author, :files
    
    def initialize(opts={})
      @number  = opts[:number]
      @message = opts[:message]
      @time    = Time.now
      @author  = "gthreepwood@monkeyisland.gov"
      @files   = []
    end
    
    def ==(other); true; end
  
    def to_s
      "#{number}: #{message}"
    end
  end
end