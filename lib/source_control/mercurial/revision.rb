module SourceControl
  class Mercurial

    # TODO: Mercurial revision so far is just like Subversion revision; maybe all three are really the same?
    class Revision < ::SourceControl::Subversion::Revision
    end
  end
end
