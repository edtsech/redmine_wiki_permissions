module WikiPermissions
  module MemberRwp
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
	unloadable
        has_many :wiki_page_user_permissions
      end
    end

    module InstanceMethods
    end
  end
end
