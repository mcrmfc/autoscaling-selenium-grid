require 'bundler/setup'
require 'selenium-webdriver'

client = Selenium::WebDriver::Remote::Http::Default.new
client.timeout = 600

driver = Selenium::WebDriver.for(:remote, :url => "http://#{ARGV[0]}:4444/wd/hub", :http_client => client, :desired_capabilities => :chrome)

wait = Selenium::WebDriver::Wait.new(:timeout => 10)

200.times do
  driver.navigate.to ARGV[1]
  puts driver.title
  sleep_time = (1..10).to_a.sample
  puts "sleeping for #{sleep_time} seconds..."
  sleep sleep_time
end

driver.quit
