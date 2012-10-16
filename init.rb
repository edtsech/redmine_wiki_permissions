require 'redmine'
require 'wiki_permissions/hook'
require 'diff'
require 'rubygems'

require 'dispatcher'
Dispatcher.to_prepare :redmine_wiki_permissions do
  unless WikiPage.included_modules.include? WikiPermissions::WikiPageRwp
    WikiPage.send(:include, WikiPermissions::WikiPageRwp)
  end

  unless WikiController.included_modules.include? WikiPermissions::WikiControllerRwp
    WikiController.send(:include, WikiPermissions::WikiControllerRwp)
  end

  unless SearchController.included_modules.include? WikiPermissions::SearchControllerRwp
    SearchController.send(:include, WikiPermissions::SearchControllerRwp)
  end

  unless User.included_modules.include? WikiPermissions::UserRwp
    User.send(:include, WikiPermissions::UserRwp)
  end

  unless Member.included_modules.include? WikiPermissions::MemberRwp
    Member.send(:include, WikiPermissions::MemberRwp)
  end

  unless Redmine::WikiFormatting::Macros::Definitions.included_modules.include? WikiPermissions::MacrosRwp
    Redmine::WikiFormatting::Macros::Definitions.send(:include, WikiPermissions::MacrosRwp)
  end
end

Redmine::Plugin.register :redmine_wiki_permissions do
  name 'Redmine Wiki Permissions plugin'
  author 'Equelli'
  description 'This redmine plugin adding permissions for every wiki page'
  version '0.0.1'
  requires_redmine :version => ['1.4.0', '1.4.1', '1.4.2', '1.4.3', '1.4.4', '1.4.5', '1.4.6', '1.4.7', '1.4.8', '1.4.9']
  
  project_module :wiki do
    permission :edit_wiki_permissions, { :wiki => [:permissions, :create_wiki_page_user_permissions, :update_wiki_page_user_permissions, :destroy_wiki_page_user_permissions] }
  end
end
