module APN
  module Connection
    module Base

      # Open socket to Apple's servers
      def setup_connection
        log_and_die("Missing apple push notification certificate") unless @apn_cert
        return true if @socket && @socket_tcp
        log_and_die("Trying to open half-open connection") if @socket || @socket_tcp

        ctx = OpenSSL::SSL::SSLContext.new
        ctx.cert = OpenSSL::X509::Certificate.new(@apn_cert)
        if @opts[:cert_pass]
          ctx.key = OpenSSL::PKey::RSA.new(@apn_cert, @opts[:cert_pass])
        else
          ctx.key = OpenSSL::PKey::RSA.new(@apn_cert)
        end

        @socket_tcp = TCPSocket.new(apn_host, apn_port)
        @socket = OpenSSL::SSL::SSLSocket.new(@socket_tcp, ctx)
        @socket.sync = true
        @socket.connect
      rescue SocketError => error
        log_and_die("Error with connection to #{apn_host}: #{error}")
      end
    end
  end

  class SenderDaemon

    def initialize(args)
      @options = {:worker_count => 1, :environment => :development, :delay => 5}

      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] start|stop|restart|run"

        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit 1
        end
        opts.on('-e', '--environment=NAME', 'Specifies the environment to run this apn_sender under ([development]/production).') do |e|
          @options[:environment] = e
        end
        opts.on('--cert-path=NAME', 'Path to directory containing apn .pem certificates.') do |path|
          @options[:cert_path] = path
        end
        opts.on('c', '--full-cert-path=NAME', 'Full path to desired .pem certificate (overrides environment selector).') do |path|
          @options[:full_cert_path] = path
        end
        opts.on('--cert-pass=PASSWORD', 'Password for the apn .pem certificates.') do |pass|
          @options[:cert_pass] = pass
        end
        opts.on('-n', '--number-of-workers=WORKERS', "Number of unique workers to spawn") do |worker_count|
          @options[:worker_count] = worker_count.to_i rescue 1
        end
        opts.on('-v', '--verbose', "Turn on verbose mode") do
          @options[:verbose] = true
        end
        opts.on('-V', '--very-verbose', "Turn on very verbose mode") do
          @options[:very_verbose] = true
        end
        opts.on('-d', '--delay=D', "Delay between rounds of work (seconds)") do |d|
          @options[:delay] = d
        end
      end

      # If no arguments, give help screen
      @args = optparse.parse!(args.empty? ? ['-h'] : args)
      @options[:verbose] = true if @options[:very_verbose]
    end
  end

end
