################################################################################
##
##  The ConsolePrinter class 
##  Uses the curses library to print the console output
##
##  Uses custom formatting to come up with the output for the console dashboard
##  Also, the historical alerts are organized with the latest alerts on top. 
##  This allows the user to see the latest alerts from the dashboard while the 
##  oldest might be lost if the data doesn't fit the screen. 
##
##  Uses arrays to keep track of the messages that have been displayed so far
##    - The statistics array keeps track of the current statistics. It is only
##      cleared by a call to the print_stats method which is only invoked by 
##      the statistics thread. 
##    - The historical_alerts array keeps track of all the alerts and when they
##      were cleared. Alerts are appended to it each time, they are cleared. 
##      A currently 'on' alert is not appended to this array. 
##    - The current_alert is a string that keeps track of the current alert 
##      message. This message can also be a cleared-alert message 
##
################################################################################

require 'curses'
require 'thread_safe'

module LogMonitor
  class ConsolePrinter
    
    def initialize(logger)
      @logger = logger

      @historical_alerts = ThreadSafe::Array.new
      @statistics = ThreadSafe::Array.new
      @current_alert = ""

      Curses.noecho
      Curses.init_screen
    end

    def shutdown
      Curses.close_screen
    end

    def print_alarm(request_count, time)
      @current_alert = ""
      time_str = Time.at(time).to_s
      msg = "High traffic generated an alert - hits = #{request_count}, " +
            "triggered at #{time_str}\n"
      @current_alert = msg

      print
    end

    def clear_alarm(time)
      time_str = Time.at(time).to_s

      msg = @current_alert.strip + ". Cleared at #{time_str}\n"
      @historical_alerts << msg
      @current_alert = ""

      msg = "Request count is back to normal at #{time_str}\n"
      @current_alert = msg

      @logger.info("Clearing alarm with message: #{msg}")
      print
    end

    def print_stats(stats)
      @statistics.clear

      section, count = stats[:section]
      msg = "Most commonly visited section: #{section} with #{count} visits\n"
      msg += "Total number of requests seen so far: #{stats[:requests]}\n"
      msg += "Total number of HTTP GET requests seen so far: #{stats[:get_requests]}\n"
      msg += "Total number of 200 responses seen so far: #{stats[:successful_requests]}\n"
      msg += "Most frequent client: #{stats[:most_frequent_client]}\n"
      msg += "Total number of unique clients: #{stats[:unique_clients]}\n"
      @statistics << msg

      print 
    end

    def print

      # Clear the screen and set up the position of cursor
      Curses.clear
      Curses.setpos(0, 0)
  
      msg = "Current statistics\n"
      msg += "======================================\n"
      msg += @statistics.join("")

      msg += "\n"
      msg += "Current Alerts\n"
      msg += "======================================\n"
      msg += @current_alert

      msg += "\n"
      msg += "Historical Alerts\n"
      msg += "======================================\n"
      msg += @historical_alerts.reverse.join("")

      Curses.addstr(msg)
      Curses.refresh
    end

  end #class
end #module

