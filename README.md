LogMonitor
===========

A simple log monitor that is used to monitor a HTTP access log written to in the [Common Log Format](http://www.w3.org/Daemon/User/Config/Logging.html).

The application uses the console to display a dashboard of the current statistics and if there are any current alerts. The dashboard also shows the history of alerts and when they were cleared. 

An alert is raised if the number of requests processed by the webserver and recorded in the log exceed a given threshold for a given period of time. Both the threshold and the time period are user-configurable. 

The historical alerts are ordered in reverse chronological order i.e. the newest alerts that have been cleared are displayed first. This allows the user to see the most recent alerts if the screen does fill up with alerts

Uses the curses library to re-draw the screen and display the dashboard. 


Usage
------

Pre-requisites:

Needs [bundler](http://bundler.io) to setup the ruby dependencies (rspec and simplecov). Run the following
```
$ gem install bundler
$ git clone https://github.com/maranellored/LogMonitor.git 
$ cd LogMonitor
$ bundle install
```

To use with bundler, run the following.
```
$ bundle exec bin/logMonitor -f /private/var/log/apache2/access_log -s 10 -i 0.05 -t 3
```
To view the usage for the program, run
```
$ bundle exec bin/logMonitor -h
```

Sample output from the program is shown below
```
Current statistics
======================================
Most commonly visited section: http://localhost/files with 1021 visits
Total number of requests seen so far: 2217
Total number of HTTP GET requests seen so far: 2217
Total number of 200 responses seen so far: 1010
Most frequent client: 127.0.0.1
Total number of unique clients: 2

Current Alerts
======================================
Request count is back to normal at 2015-03-17 19:10:13 -0700

Historical Alerts
======================================
High traffic generated an alert - hits = 7, triggered at 2015-03-17 19:09:46 -0700. Cleared at 2015-03-17 19:10:13 -0700
High traffic generated an alert - hits = 6, triggered at 2015-03-17 19:09:22 -0700. Cleared at 2015-03-17 19:09:24 -0700
```

To quit the program at any time, use Ctrl+C


To run the rspec test for the alerting logic, run the following
```
$ bundle exec rspec
```

**NOTE:** This has been tested with ruby 2.1.1
