class WikiPageUserPermission < ActiveRecord::Base
  attr_accessible :level, :user_id, :wiki_page_id 
end
