################################################################################
##
##  The LogMonitor class. 
##  Used to monitor an apache access log for patterns and metrics
##
################################################################################

require 'apachelogregex'
require 'consolePrinter'
require 'statBuffer'

require 'pry'

module LogMonitor

  class LogMonitor
    
    COMMON_LOG_FORMAT = '%h %l %u %t \"%r\" %>s %b'

    def initialize(filename, alarm_threshold, alarm_interval, stats_frequency, logger)
      @logger = logger

      @filename = filename
      @stats_frequency = stats_frequency

      @parser = ApacheLogRegex.new(COMMON_LOG_FORMAT)
    
      @printer = ConsolePrinter.new(@logger)

      @stats_buffer = StatBuffer.new(alarm_interval, alarm_threshold, @printer, @logger)

      # Setup a signal handler to handle process stoppage
      Signal.trap('INT') do
        puts "Shutting down....."
        stop
      end
    end
    
    def start
      @keep_running = true
      file = File.open(@filename, 'r')

      @parser_thread = Thread.new{log_parser(file)}
      @stats_thread = Thread.new{gather_statistics}

      @stats_thread.join
      @parser_thread.join

      @printer.shutdown
      file.close
    end
    
    def log_parser(file)
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
        rescue Exception => e
          @logger.error("Exception while reading line: #{e.message}")
          next
        end
        
        begin
          process(line)
        rescue Exception => e
          # FIXME: Remove the catchall exception from here
          # found an error while processing request
          # skip this one
          @logger.error("Exception while processing line: #{line}\n" +
                        "Message: #{e.message}")
          next
        end
      end

      @logger.info("Finished executing. Quitting...")

    end

    def stop
      @keep_running = false
    end

    def process(line)
      # Regex match here to make sure that the line is valid
      begin
        result = @parser.parse!(line)
      rescue ApacheLogRegex::ParseError => e
        # Found an invalid log line
        return  
      end

      requester = result['%h']
      method, url, protocol = result['%r'].split
      section = url.split('/')[0..1].join('/')
      # Remove braces from the timestamp
      timestamp_string = result['%t'].delete('[]')
      # Get seconds since epoch
      timestamp = Time.parse(timestamp_string.sub(":", " ")).to_i
      
      # now add this to my internal structure and just display it
      @stats_buffer.add_section(section)
      @stats_buffer.add_request(timestamp)
    end

    def gather_statistics
      while @keep_running
        sleep(@stats_frequency)
        stats_map = {}
        section, count = @stats_buffer.find_most_common_section
        total_requests = @stats_buffer.get_total_requests
        stats_map[:section] = [section, count]
        stats_map[:requests] = total_requests
        @printer.print_stats(stats_map)
      end
    end

  end # Class end

end # Module end
