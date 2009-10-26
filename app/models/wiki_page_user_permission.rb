class WikiPageUserPermission < ActiveRecord::Base
  #attr_accessible :level, :user_id, :wiki_page_id
  #belongs_to :member
  belongs_to :wiki_page
  
  def user
    User.find member.user_id
  end
  
  def member
    Member.find member_id
  end
end
