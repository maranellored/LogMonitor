
require 'spec_helper'
require 'stat_buffer'

describe LogMonitor::StatsBuffer do
  
  describe ".check_if_alarm_breached" do
    it 'Tests if we can verify that the alarm has been breached' do
      time_interval = 0.1
      alarm_threshold = 3

      console_printer = mock('console_printer')
      logger = mock('logger')
      
      console_printer.should_receive('print_alarm').with(5, 5)
      logger.should_receive('info')

      buffer = StatsBuffer.new(time_interval, alarm_threshold, console_printer, logger)

      buffer.add_request(1)
      buffer.add_request(2)
      buffer.add_request(2)
      buffer.add_request(2)
      buffer.add_request(4)

      buffer.check_if_alarm_breached(5)
    end
  end

end
