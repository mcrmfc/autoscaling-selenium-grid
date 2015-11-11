#
# Cookbook Name:: grid-node
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

selenium_node 'selenium_node' do
  capabilities [
    {
      browserName: 'chrome',
      maxInstances: node['selenium']['chrome']['instances'],
      seleniumProtocol: 'WebDriver'
    }
  ]
  action :install
end
