module WikiPermissions
  module WikiController
    def self.included base
      base.class_eval do
        
        def permissions
          render :template => 'wiki/edit_permissions'
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
end