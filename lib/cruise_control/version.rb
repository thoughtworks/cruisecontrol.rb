module CruiseControl
  module VERSION #:nodoc:
    unless defined? MAJOR
      MAJOR = 1 
      MINOR = 2
      MAINTENANCE = 1

      STRING = [MAJOR, MINOR, MAINTENANCE].join('.')
    end
  end
end
