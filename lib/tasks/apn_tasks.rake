# Slight modifications from the default Resque tasks
namespace :apn do
  task :setup => :environment
  task :work => :sender
  task :workers => :senders

  desc "Start an APN worker"
  task :sender => :setup do
    worker = nil

    begin
      worker = APN::Sender.new(:full_cert_path => ENV['FULL_CERT_PATH'], :cert_path => ENV['CERT_PATH'], :environment => ENV['ENVIRONMENT'], :cert_pass => ENV['CERT_PASS'])
      worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
      worker.very_verbose = ENV['VVERBOSE']
    rescue Exception => e
      raise e
      # abort "set QUEUE env var, e.g. $ QUEUE=critical,high rake resque:work"
    end

    puts "*** Starting worker to send apple notifications in the background from #{worker}"

    worker.work(ENV['INTERVAL'] || 5) # interval, will block
  end

  desc "Start multiple APN workers. Should only be used in dev mode."
  task :senders do
    threads = []

    ENV['COUNT'].to_i.times do
      threads << Thread.new do
        system "rake apn:work"
      end
    end

    threads.each { |thread| thread.join }
  end

  desc "Clear tokens for uninstalled applications"
  task :clear_tokens => :setup do
    feedback_data = APN::Feedback.new(:environment => :production).data(true)
    feedback_data.each do |item|
      user = User.where(:iphone_token => item.token).first

      if user.iphone_token_updated_at && user.iphone_token_updated_at > item.timestamp
        return true # App has been reregistered since Apple determined it'd been uninstalled
      else
        user.update_attributes(:iphone_token => nil, :iphone_token_updated_at => Time.now) 
      end
    end
  end
end
