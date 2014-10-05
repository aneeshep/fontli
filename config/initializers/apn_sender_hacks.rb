module APN
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
