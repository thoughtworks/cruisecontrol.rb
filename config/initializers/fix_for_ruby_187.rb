# https://rails.lighthouseapp.com/projects/8994/tickets/867-undefined-method-length-for-enumerable
class String
  def chars
    ActiveSupport::Multibyte::Chars.new(self)
  end
  alias_method :mb_chars, :chars
end
