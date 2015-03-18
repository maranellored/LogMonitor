################################################################################
##
##  The LogMonitor class.
##  Used to monitor a HTTP access log for patterns and metrics
##
##  The monitor makes use of threads to monitor the log files separately.
##    - The parser thread is responsible for reading data from the log file,
##      parsing each log line and storing it in the stats buffer class. This
##      thread will sleep for 1 second between polling for new log events
##    - The stats thread is responsible for reading the stats from the stats
##      buffer class and printing the relevant stats on the screen. This
##      thread will sleep for the user-specified time interval each time
##      before posting the statistics about the web server
##    - The alerter thread is responsible for evaluating the buffered request
##      stats and evaluating if the alert threshold has been breached. This
##      thread will run every 1 second.
##
##  An alternative approach to having a separate alerter thread is to actually
##  evaluate the alarm threshold every time a request is made in the log.
##  This would help concurrency and wouldn't require the need of any special
##  data structures. But this method could cause alert-clearing events to be
##  missed if no request comes in for a long time. Thus, having the 1 second
##  delayed alerter thread provides a better way of handling this condition
##  immediately as it happens.
##
################################################################################

require 'apachelogregex'
require 'console_printer'
require 'stat_buffer'

module LogMonitor

  class LogMonitor

    COMMON_LOG_FORMAT = '%h %l %u %t \"%r\" %>s %b'

    def initialize(filename, alarm_threshold, alarm_interval, stats_frequency, url, logger)
      @logger = logger

      @url = url
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
      @alerter_thread = Thread.new{generate_alerts}

      @alerter_thread.join
      @stats_thread.join
      @parser_thread.join

      @printer.shutdown
      file.close
    end

    def stop
      @keep_running = false
      @printer.shutdown
    end

    # Everything below here are private methods used internally
    # by this logmonitor class.
    private
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

    # Uses apachelogregex to parse the log line into the relevant
    # parts. Once parsed, the parts are individually stored in different
    # metrics.
    def process(line)
      # Regex match here to make sure that the line is valid
      begin
        result = @parser.parse!(line)
      rescue ApacheLogRegex::ParseError => e
        # Found an invalid log line
        @logger.error("Invalid log line in file - #{line}")
        return
      end

      requester = result['%h']
      method, resource, protocol = result['%r'].split
      section = @url + resource.split('/')[0..1].join('/')
      status = result['%>s']
      # Remove braces from the timestamp
      timestamp_string = result['%t'].delete('[]')
      # Get seconds since epoch
      timestamp = Time.parse(timestamp_string.sub(":", " ")).to_i

      # now add this to my internal structure and just display it
      @stats_buffer.add_request(timestamp)
      @stats_buffer.add_section(section)
      @stats_buffer.add_get_request if method.upcase.eql? 'GET'
      @stats_buffer.add_successful_request if status.eql? "200"
      @stats_buffer.add_client_address(requester)
    end

    # A method used by a thread to gather statistics about the web
    # server from the log files.
    # The statistics are stored everytime a request is processed
    # This method only retrieves ths stats and publishes them to the
    # console.
    def gather_statistics
      while @keep_running
        stats_map = {}
        section, count = @stats_buffer.find_most_common_section
        stats_map[:section] = [section, count]
        stats_map[:requests] = @stats_buffer.total_requests
        stats_map[:get_requests] = @stats_buffer.get_requests
        stats_map[:successful_requests] = @stats_buffer.successful_requests
        stats_map[:unique_clients] = @stats_buffer.get_unique_clients
        stats_map[:most_frequent_client] = @stats_buffer.get_most_frequent_client
        @printer.print_stats(stats_map)
        sleep(@stats_frequency)
      end
    end

    # A method that is used by a thread to check the alarm conditions
    # This is necessary so that we can perform the check on the alert
    # irrespective of there being requests flowing to the web server or
    # not
    def generate_alerts
      while @keep_running
        current_time = Time.new.to_i
        @stats_buffer.prune_old_values(current_time)
        @stats_buffer.check_if_alarm_breached(current_time)

        #Sleep for a second
        sleep(1)
      end

    end

  end # Class end

end # Module end
