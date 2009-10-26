module WikiPermissions
  module WikiPage
    def self.included base
      
      base.class_eval do
        has_many :permissions, :class_name => 'WikiPageUserPermission'
      end
      
      def leveled_permissions level
        debugger
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
        #debugger
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
        #debugger
        project.members - members_with_permissions
      end
      
      def members_with_permissions
        members_wp = Array.new
        permissions.each do |permission|
          members_wp << permission.member
        end
        members_wp
      end
    end
  end 
  
  module Member
    def self.included base
      base.class_eval do
        has_many :wiki_page_user_permissions
      end
    end
  end
  module User
    def self.included base
      base.class_eval do
        
        alias_method :_allowed_to?, :allowed_to? unless method_defined? :_allowed_to?

        def allowed_to?(action, project, options={})
          allowed_actions = [
            'create_wiki_page_user_permissions',
            'destroy_wiki_page_user_permissions'
          ]
          
          if action.class == Hash and action[:controller] == 'wiki' and allowed_actions.include? action[:action] 
            return true
          else
            _allowed_to?(action, project, options={})
          end
        end
      end
    end
  end
  module WikiController
    def self.included base
      base.class_eval do
        
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

  WikiController.send :include, WikiPermissions::WikiController
  User.send :include, WikiPermissions::User
  Member.send :include, WikiPermissions::Member
  WikiPage.send :include, WikiPermissions::WikiPage
end