module CruiseControl
  module VERSION #:nodoc:
    unless defined? MAJOR
      MAJOR = 1 
      MINOR = 1
      MAINTENANCE = 0

      STRING = [MAJOR, MINOR, MAINTENANCE].join('.')
    end
  end
end
