module WikiPermissions
  module WikiPageRwp
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
	unloadable
        has_many :permissions, :class_name => 'WikiPageUserPermission'
        alias_method_chain :visible?, :wiki_permissions
        after_create :role_creator
      end
    end

    module InstanceMethods

      def rwp_page_visible?(project, user)
	page = WikiPage.find(id)
	!user.nil? && user.can_view?(page)
      end

      def visible_with_wiki_permissions?(user=User.current)
        allowed = visible_without_wiki_permissions?(user)
	if allowed
	  return rwp_page_visible?(project, user)
	end
	allowed
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
end
