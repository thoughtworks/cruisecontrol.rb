module CruiseControl
  module VERSION #:nodoc:
    unless defined? MAJOR
      MAJOR = 0 
      MINOR = 2

      STRING = [MAJOR, MINOR].join('.')
    end
  end
end
