module SourceControl
  class AbstractRevision

    include Comparable

    def <=>(other)
      raise NotImplementedError
    end

  end
end