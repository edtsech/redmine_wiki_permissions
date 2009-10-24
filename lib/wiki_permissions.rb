module WikiPermissions
  module User
    def self.included base
      base.class_eval do
               
        def allowed_to?(action, project, options={})
          if action[:controller] == 'wiki' and action[:action] == 'create_wiki_page_user_permissions'
            return true
          else
            if project
              # No action allowed on archived projects
              return false unless project.active?
              # No action allowed on disabled modules
              return false unless project.allows_to?(action)
              # Admin users are authorized for anything else
              return true if admin?

              role = role_for_project(project)
              return false unless role
              role.allowed_to?(action) && (project.is_public? || role.member?)

            elsif options[:global]
              # authorize if user has at least one role that has this permission
              roles = memberships.collect {|m| m.role}.uniq
              roles.detect {|r| r.allowed_to?(action)} || (self.logged? ? Role.non_member.allowed_to?(action) : Role.anonymous.allowed_to?(action))
            else
              false
            end
          end
        end
        
      end
    end
  end
  module WikiController
    def self.included base
      base.class_eval do
        
        def index
          page_data_logic
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
          render :template => 'wiki/edit_permissions'
        end
        
        def create_wiki_page_user_permissions
          @wiki_page_user_permission = WikiPageUserPermission.new(params[:wiki_page_user_permission])
          if @wiki_page_user_permission.save
            redirect_to :action => 'index'
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
end