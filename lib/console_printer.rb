################################################################################
##
##  The ConsolePrinter class 
##  Uses the curses library to print the console output
#@  
################################################################################

require 'curses'

module LogMonitor
  class ConsolePrinter
    
    def initialize(logger)
      @logger = logger

      @historical_alerts = []
      @statistics = []
      @current_alert = []

      Curses.noecho
      Curses.init_screen
    end

    def shutdown
      Curses.close_screen
    end

    def print_alarm(request_count, time)
      @current_alert.clear
      time_str = Time.at(time).to_s
      msg = "High traffic generated an alert - hits = #{request_count}, " +
            "triggered at #{time_str}\n"
      @current_alert << msg

      print
    end

    def clear_alarm(time)
      @historical_alerts << @current_alert[0]
      @current_alert.clear

      time_str = Time.at(time).to_s
      msg = "Request count is back to normal at #{time_str}\n"
      @current_alert << msg

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
      @statistics << msg

      print 
    end

    def print

      # Clear the screen and set up the position of cursor
      Curses.clear
      Curses.setpos(0, 0)
  
      msg = "Historical Alerts\n"
      msg += "======================================\n"
      msg += @historical_alerts.join("")

      msg += "\n"
      msg += "Current statistics\n"
      msg += "======================================\n"
      msg += @statistics.join("")

      msg += "\n"
      msg += "Current Alerts\n"
      msg += "======================================\n"
      msg += @current_alert.join("")
      msg += "\n"

      Curses.addstr(msg)
      Curses.refresh
    end

  end #class
end #module

