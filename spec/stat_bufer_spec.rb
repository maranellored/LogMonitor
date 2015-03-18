
require 'stat_buffer'

describe LogMonitor::StatBuffer do
  
  before :each do
      time_interval = 0.1
      alarm_threshold = 3
      # Setup mocks for the console printer and logger classes
      @console_printer = double('console_printer')
      @logger = double('logger')

      @buffer = LogMonitor::StatBuffer.new(time_interval, alarm_threshold, @console_printer, @logger)
  end

  describe ".check_if_alarm_breached" do
    it 'Tests if we can verify that the alarm has been breached' do
      
      # Set logger expectations
      expect(@logger).to receive(:debug).at_least(:once)
      expect(@logger).to receive(:info).at_least(:once)
      # Set expected values for the console printer and mock class
      expect(@console_printer).to receive(:print_alarm).with(5, 5)

      @buffer.add_request(1)
      @buffer.add_request(2)
      @buffer.add_request(2)
      @buffer.add_request(2)
      @buffer.add_request(4)

      @buffer.check_if_alarm_breached(5)
      
      # Prune old values
      @buffer.prune_old_values(9)
      
      expect(@console_printer).to receive(:clear_alarm).with(9)
      # Check again if the alarm has breached. 
      # This should not cause the alarm to go off
      @buffer.check_if_alarm_breached(9)
    end

    it "Tests if we can verify that the alarm is not breached" do
      expect(@logger).to receive(:debug).at_least(:once)
      # We dont want to call the print_alarm method
      expect(@console_printer).to_not receive(:print_alarm)
      
      @buffer.add_request(1)
      @buffer.add_request(2)
      @buffer.add_request(2)

      @buffer.check_if_alarm_breached(3)
    end
  end

end
