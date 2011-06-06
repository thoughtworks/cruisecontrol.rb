module CruiseControl
  module VERSION #:nodoc:
    unless defined? MAJOR
      MAJOR = 2
      MINOR = 0
      MAINTENANCE = 0
      SPECIAL = "pre1"

      STRING = [MAJOR, MINOR, MAINTENANCE].join('.') + SPECIAL
    end
  end
end
