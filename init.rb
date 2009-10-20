require 'redmine'
require 'diff'
require 'rubygems'
require File.dirname(__FILE__) + '/lib/wiki_permissions.rb'

Redmine::Plugin.register :redmine_wiki_permissions do
  name 'Redmine Wiki Permissions plugin'
  author 'Equelli'
  description 'This is a plugin for Redmine'
  version '0.0.1'
end
