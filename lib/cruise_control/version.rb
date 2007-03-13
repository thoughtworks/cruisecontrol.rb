module CruiseControl
  module VERSION #:nodoc:
    unless defined? MAJOR
      MAJOR = 1 
      MINOR = 0
      MAINTENANCE = '+'

      STRING = [MAJOR, MINOR, MAINTENANCE].join('.')
    end
  end
end
