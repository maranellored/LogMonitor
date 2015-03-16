################################################################################
##
##  The LogMonitor class. 
##  Used to monitor an apache access log for patterns and metrics
##
################################################################################

require 'signal'
require 'apachelogregex'

module LogMonitor

  class LogMonitor
    
    COMMON_LOG_FORMAT = '%h %l %u %t "%r" %>s %b'

    def initialize(filename, alarm_threshold, alarm_internval, stats_frequency)
      @filename = filename
      @alarm_threshold = alarm_threshold
      @alarm_interval = alarm_interval
      @stats_frequency = stats_frequency

      @parser = ApacheLogRegex.new(COMMON_LOG_FORMAT)
      # Setup a signal handler to handle process stoppage
      Signal.trap('INT') do
        puts "Shutting down....."
        stop()
      end
    end
    
    def start
      @keep_running = true
      file = File.open(@filename, 'r')
      # FIXME: Start statistics thread
      
      loop do
        # Break if we don't want to run anymore.
        break if not @keep_running
        
        begin
          line = file.readline
        rescue EOFError
          # we've reached the end of file
          # dont bail. sleep for a second to try again
          sleep(1)
          next
        end

        process(line)
      end

    end

    def process(line)
      # Regex match here to make sure that the line is valid
      begin
        result = @parser.parse!(line)
      rescue ApacheLogRegex::ParseError
        # Found an invalid log line
        return  
      end

      requester = result['%h']
      method, url, protocol = result['%r'].split
      section = url.split('/')[0..1].join('/')
      # Remove braces from the timestamp
      timestamp_string = result['%t'].delete('[]')
      # Get seconds since epoch
      timestamp = Time.parse(timestamp_string.sub(":", "")).to_i
      
      # now add this to my internal structure and just display it
    end

  end

end


