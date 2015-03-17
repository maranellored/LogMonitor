################################################################################
##
##  The StatBuffer class 
##  Used to keep track of the stats in memory. 
##  Uses counters to keep track of historic values
##  Uses a queue to keep track of requests in the past time
##
################################################################################

require 'time'
require 'thread'

module LogMonitor
  
  class StatBuffer
    
    attr_reader :total_requests, :successful_requests, :get_requests

    def initialize(time_interval, alarm_threshold, console_printer, logger)
      @logger = logger

      # used to keep track of the requests in the past time
      @queue = []

      # Create a hash to keep track of the sections. 
      # This hash will give out default values of 0 
      @section_counter = Hash.new 0
      @total_requests = 0
      @successful_requests = 0
      @get_requests = 0

      @time_interval = time_interval * 60
      @alarm_threshold = alarm_threshold

      @printer = console_printer

      @in_alarm = false
    end

    # Add a section to the hash counter
    # Called everytime a request is parsed from the logfile
    def add_section(section)
      @section_counter[section] += 1
    end

    def add_successful_request
      @successful_requests += 1
    end

    def add_get_request
      @get_requests += 1
    end

    # Retrieves the most common section that is available
    # The parameter, x allows for the user to specify the top 'x' sections
    # Returns an array with key as the first element and the value as second
    def find_most_common_section
      return @section_counter.max_by{|k, v| v}
    end

    # Add the request timestamp to the queue
    # Perform checks to ensure that we only keep the required values
    def add_request(timestamp)
      # add to total requests
      @total_requests += 1
      @logger.debug("Pushing timestamp: #{Time.at(timestamp).to_s}")
      @queue.push(timestamp)
    end

    # Prune the old values from the queue. 
    # Values are basically the timestamps that exist. 
    # Assumption is that time never goes backward and all timestamps from
    # the log files are always in increasing order
    def prune_old_values(current_time)
      pruning_time = current_time - @time_interval
      @logger.info("Pruning time: #{Time.at(pruning_time).to_s}")
      # iterate over the queue and remove values that are older than 2 minutes
      @queue.delete_if {|ts| ts < pruning_time} 
    end

    # Checks the current queue size is greater than the specified alarm
    # threshold. 
    # Prints a message to the printer if the threshold is exceeded.
    def check_if_alarm_breached(current_time)
      if @queue.length > @alarm_threshold
        @logger.debug("Queue length while alarming is #{@queue.length}")
        @printer.print_alarm(@queue.length, current_time) unless @in_alarm
        @in_alarm = true
      else
        @logger.debug("Queue length is #{@queue.length}")
        @printer.clear_alarm(current_time) if @in_alarm
        @in_alarm = false
      end
    end

  end # Class end
end # Module end

