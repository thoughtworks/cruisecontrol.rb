module CruiseControl
  module VERSION #:nodoc:
    unless defined? MAJOR
      MAJOR = 0 
      MINOR = 3
      MAINTENANCE = 0

      STRING = [MAJOR, MINOR, MAINTENANCE].join('.')
    end
  end
end
