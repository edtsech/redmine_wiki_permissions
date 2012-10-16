module WikiPermissions
  module WikiControllerRwp
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
	unloadable
        helper_method :include_module_wiki_permissions?
        alias_method :_index, :index unless method_defined? :_index
        alias_method_chain :show, :wiki_permissions
        alias_method_chain :edit, :wiki_permissions
        alias_method_chain :update, :wiki_permissions
        
        def index
          _index
        end
      end
    end

    module InstanceMethods

      def show_with_wiki_permissions
        show_without_wiki_permissions
	if !User.current.not_has_permission?(@page) and !User.current.can_view?(@page)
	  deny_wiki_permissions
	end
      end

      def edit_with_wiki_permissions
        edit_without_wiki_permissions
        unless @page.new_record?
	  if !User.current.not_has_permission?(@page) and !User.current.can_edit?(@page)
	    deny_wiki_permissions
	  end
        end
      end

      def update_with_wiki_permissions
        find_existing_or_new_page
        if @page
	  if !User.current.not_has_permission?(@page) and !User.current.can_edit?(@page)
	    deny_wiki_permissions
	    return false
	  end
        end
        update_without_wiki_permissions
      end

      def authorize ctrl = params[:controller], action = params[:action]
	allowed = User.current.allowed_to?({ :controller => ctrl, :action => action }, @project, { :params => params })
	allowed ? true : deny_access
      end
      
      def permissions
	find_existing_page
	@wiki_page_user_permissions = WikiPageUserPermission.all :conditions => { :wiki_page_id => @page.id }
	render :template => 'wiki/edit_permissions'
      end
      
      def create_wiki_page_user_permissions
	@wiki_page_user_permission = WikiPageUserPermission.new(params[:wiki_page_user_permission])
	if @wiki_page_user_permission.save
	  redirect_to :action => 'permissions'
	else
	  render :action => 'new'
	end
      end
      
      def update_wiki_page_user_permissions
	params[:wiki_page_user_permission].each_pair do |index, level|
	  permission = WikiPageUserPermission.find index.to_i
	  permission.level = level.to_i
	  permission.save
	end
	redirect_to :back
      end
      
      def destroy_wiki_page_user_permissions
	WikiPageUserPermission.find(params[:permission_id]).destroy
	      redirect_to :back
      end
      
      def include_module_wiki_permissions?
	(@page.project.enabled_modules.detect { |enabled_module| enabled_module.name == 'wiki_permissions' }) != nil
      end

      private
      def deny_wiki_permissions
        self.erase_render_results
        deny_access
      end
    end
  end
end
