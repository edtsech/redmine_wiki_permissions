module WikiPermissions
  module UserRwp
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
	unloadable
        alias_method :_allowed_to?, :allowed_to? unless method_defined? :_allowed_to?
      end
    end

    module InstanceMethods
        
      def not_has_permission? page
	admin or
	WikiPageUserPermission.first(
	  :conditions => {
	    :wiki_page_id => page.id,
	    :member_id => Member.first(:conditions => { :user_id => id, :project_id => page.project.id }).id
	  }
	) == nil
      end
      
      def user_permission_greater? page, lvl          
	admin or (
	as_member = Member.first(
	  :conditions => { :user_id => id, :project_id => page.project.id }
	) and
	wpup = WikiPageUserPermission.first(
	  :conditions => {
	    :wiki_page_id => page.id,
	    :member_id => as_member.id
	  }
	) and wpup.level >= lvl)
      end
      
      def can_edit? page
	user_permission_greater? page, 2
      end
	      
      def can_edit_permissions? page
	user_permission_greater? page, 3
      end
      
      def can_view? page          
	user_permission_greater? page, 1
      end

      def allowed_to?(action, project, options={})
	allowed_actions = [
	  'create_wiki_page_user_permissions',
	  'destroy_wiki_page_user_permissions'
	]
	
	if project != nil
	  if project.enabled_modules.detect { |enabled_module| enabled_module.name == 'wiki_permissions' } != nil and \
	    action.class == Hash and action[:controller] == 'wiki'
	    if User.current and User.current.admin
	      return true
	    elsif [
		'index',
		'edit',
		'permissions',                
		'create_wiki_page_user_permissions',
		'update_wiki_page_user_permissions',
		'destroy_wiki_page_user_permissions'
	      ].include? action[:action] and

	      options.size != 0 and

	      wiki_page = 
		WikiPage.first(:conditions => { :wiki_id => project.wiki.id, :title => options[:params][:page] }) and

	      permission = WikiPageUserPermission.first(:conditions => {
		  :member_id => Member.first(:conditions => { :user_id => User.current.id, :project_id => project.id }),
		  :wiki_page_id => wiki_page.id
	      }) and permission     

	      return case action[:action]
		when 'index'
		  permission.level > 0
		when 'edit'
		  permission.level > 1
		else
		  permission.level > 2
	      end
	    end
	    _allowed_to?(action, project, options)
	  #elsif action.class == Hash and action[:controller] == 'wiki' and allowed_actions.include? action[:action] 
	  #  return true
	  else
	    _allowed_to?(action, project, options)
	  end
	else
	  _allowed_to?(action, project, options)
	end
      end
    end
  end
end
