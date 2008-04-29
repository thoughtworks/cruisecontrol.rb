module SourceControl
  class << self

    def create(options)
      raise NotImplementedError
    end

    def detect(project_name)
      SourceControl::Subversion.new
    end

  end
end