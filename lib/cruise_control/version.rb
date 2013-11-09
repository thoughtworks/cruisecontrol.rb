module CruiseControl
  module VERSION #:nodoc:
    unless defined? MAJOR
      MAJOR = 3
      MINOR = 1
      MAINTENANCE = 0
      SPECIAL = ""

      STRING = [MAJOR, MINOR, MAINTENANCE].join('.') + SPECIAL
    end
  end
end
