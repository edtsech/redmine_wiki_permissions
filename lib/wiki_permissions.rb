module WikiPermissions
  module MixinSearchController
    def self.included base
      base.class_eval do
        alias_method :_index, :index unless method_defined? :_index

        def index
          _index
          
          if @results != nil
            @results.delete_if do |result|
              result.class == WikiPage and
              not User.current.can_view? result
            end
          end
        end
        
      end      
    end
  end
  module MixinWikiPage
    def self.included base
      
      base.class_eval do
        has_many :permissions, :class_name => 'WikiPageUserPermission'
        after_create :role_creator
      end
      
      def leveled_permissions level
        WikiPageUserPermission.all :conditions => { :wiki_page_id => id, :level => level }
      end
      
      def users_by_level level
        users = Array.new
        leveled_permissions(level).each do |permission|
          users << permission.user
        end
        users
      end

      def users_without_permissions
        project.users - users_with_permissions
      end
      
      def users_with_permissions
        users = Array.new
        WikiPageUserPermission.all(:conditions => { :wiki_page_id => id }).each do |permission|
          users << permission.user
        end
        users        
      end
      
      def members_without_permissions
        project.members - members_with_permissions
      end
      
      def members_with_permissions
        members_wp = Array.new
        permissions.each do |permission|
          members_wp << permission.member
        end
        members_wp
      end
      
      private      
      
      def role_creator
        member = self.wiki.project.members.find_by_user_id(User.current.id)
        WikiPageUserPermission.create(:wiki_page_id => id, :level => 3, :member_id => member.id) unless member.nil?
      end
    end
  end
  
  module MixinMember
    def self.included base
      base.class_eval do
        has_many :wiki_page_user_permissions
      end
    end
  end
  
  module MixinUser
    def self.included base
      base.class_eval do
            
        alias_method :_allowed_to?, :allowed_to? unless method_defined? :_allowed_to?
        
        def not_has_permission? page
          admin or
          WikiPageUserPermission.first(
            :conditions => {
              :wiki_page_id => page.id,
              :member_id => Member.first(:conditions => { :user_id => id, :project_id => page.project.id }).id
            }
          ) == nil
        end
        
        def user_permission_greater? page, level          
          admin or (
          as_member = Member.first(
            :conditions => { :user_id => id, :project_id => page.project.id }
          ) and
          WikiPageUserPermission.first(
            :conditions => {
              :wiki_page_id => page.id,
              :member_id => as_member.id
            }
          ).level >= level)
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
  
  module MixinWikiController
    def self.included base
      base.class_eval do
        
        helper_method :include_module_wiki_permissions?
        
        alias_method :_index, :index unless method_defined? :_index
        
        def index
          _index
        end
        
        def page_data_logic
          page_title = params[:page]
          @page = @wiki.find_or_new_page(page_title)
          if @page.new_record?
            if User.current.allowed_to?(:edit_wiki_pages, @project)
              edit
              render :action => 'edit'
            else
              render_404
            end
            return
          end
          if params[:version] && !User.current.allowed_to?(:view_wiki_edits, @project)
            # Redirects user to the current version if he's not allowed to view previous versions
            redirect_to :version => nil
            return
          end
          @content = @page.content_for_version(params[:version])
          if params[:export] == 'html'
            export = render_to_string :action => 'export', :layout => false
            send_data(export, :type => 'text/html', :filename => "#{@page.title}.html")
            return
          elsif params[:export] == 'txt'
            send_data(@content.text, :type => 'text/plain', :filename => "#{@page.title}.txt")
            return
          end
        	@editable = editable?
          render :template => 'wiki/show'
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
        
      end
    end
  end  
end

require 'dispatcher'
  Dispatcher.to_prepare do 
    begin
      require_dependency 'application'
    rescue LoadError
      require_dependency 'application_controller'
    end

  Member.send :include, WikiPermissions::MixinMember
  WikiPage.send :include, WikiPermissions::MixinWikiPage  
  WikiController.send :include, WikiPermissions::MixinWikiController
  SearchController.send :include, WikiPermissions::MixinSearchController
  User.send :include, WikiPermissions::MixinUser
end