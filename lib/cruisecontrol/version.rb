module CruiseControl
  module VERSION #:nodoc:
    unless defined? MAJOR
      MAJOR = 0 
      MINOR = 3

      STRING = [MAJOR, MINOR].join('.')
    end
  end
end
