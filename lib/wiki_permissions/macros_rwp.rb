module WikiPermissions
  module MacrosRwp
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :macro_include, :wiki_permissions
      end
    end

    module InstanceMethods
      def macro_include_with_wiki_permissions(obj, args)
        page = Wiki.find_page(args.first.to_s, :project => @project)
        if !page.nil? and page.present? and User.current.not_has_permission?(@page)
          raise 'Access to page is denied'
        end
        macro_include_without_wiki_permissions(obj, args)
      end
    end
  end
end
