#
# Cookbook Name:: grid-hub
# Recipe:: default
#
# Copyright (C) 2015 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'yum'
include_recipe 'java'
include_recipe 'chrome'
include_recipe 'xvfb'
include_recipe 'selenium::chromedriver'
include_recipe 'awscli'

selenium_hub 'selenium_hub' do
  action :install
end

template '/usr/local/selenium/grid-queue' do
  source 'grid-queue.erb'
  owner 'selenium'
  group 'selenium'
  mode '0755'
end

cron_d 'selenium_queue' do
  minute '*/1'
  user 'selenium'
  command '/usr/local/selenium/grid-queue'
end
