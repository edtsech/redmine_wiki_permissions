require 'redmine'
require 'diff'
require 'rubygems'
require File.dirname(__FILE__) + '/lib/wiki_permissions.rb'

Redmine::Plugin.register :redmine_wiki_permissions do
  name 'Redmine Wiki Permissions plugin'
  author 'Equelli'
  description 'This redmine plugin adding permissions for every wiki page'
  version '0.0.1'
  
  project_module "wiki_permissions" do
    permission :edit_wiki_permissions, { :wiki => :permissions }
  end
end
