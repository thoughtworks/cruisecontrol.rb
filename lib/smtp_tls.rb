require "net/smtp"

Net::SMTP.class_eval do
  private
  def do_start(helodomain, user, secret, authtype)
    raise IOError, 'SMTP session already started' if @started

    if user or secret
      if RUBY_VERSION < "1.8.7"
        check_auth_method(authtype || DEFAULT_AUTH_TYPE)
        check_auth_args user, secret
      else
        check_auth_args user, secret, authtype
      end
    end

    open_conversation(helodomain)

    if starttls
      create_ssl_socket(helodomain)
    else
      # some SMTP servers that don't support TLS drop the socket after rejecting
      # STARTTLS command, so reopen the conversation
      @socket.close
      open_conversation(helodomain)
    end

    authenticate user, secret, authtype if user
    @started = true
  ensure
    unless @started
      # authentication failed, cancel connection.
      @socket.close if not @started and @socket and not @socket.closed?
      @socket = nil
    end
  end

  def do_helo(helodomain)
     begin
      if @esmtp
        ehlo helodomain
      else
        helo helodomain
      end
    rescue Net::ProtocolError
      if @esmtp
        @esmtp = false
        @error_occured = false
        retry
      end
      raise
    end
  end

  def starttls
    begin
      getok('STARTTLS')
      true
    rescue
      false
    end
  end

  def create_ssl_socket(helodomain)
    require "openssl"
    ssl = OpenSSL::SSL::SSLSocket.new(@tcp_socket)
    ssl.sync_close = true
    ssl.connect
    @socket = Net::InternetMessageIO.new(ssl)
    @socket.read_timeout = 60 #@read_timeout
    @socket.debug_output = STDERR #@debug_output
    do_helo(helodomain)
  end

  def open_conversation(helodomain)
    @tcp_socket = timeout(@open_timeout) { TCPSocket.open(@address, @port) }
    @socket = Net::InternetMessageIO.new(@tcp_socket)
    @socket.read_timeout = 60 #@read_timeout
    @socket.debug_output = STDERR #@debug_output

    check_response(critical { recv_response() })
    do_helo(helodomain)
  end

  def quit
    begin
      getok('QUIT')
    rescue EOFError
    end
  end

end
