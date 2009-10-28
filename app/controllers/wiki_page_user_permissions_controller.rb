class WikiPageUserPermissionsController < ApplicationController
  unloadable

  def destroy
    WikiPageUserPermission.find(params[:id]).destroy
  	redirect_to :back
  end
  
  def update
    params[:wiki_page_user_permission].each_pair do |index, level|
      permission = WikiPageUserPermission.find index.to_i
      permission.level = level.to_i
      permission.save
    end
    redirect_to :back
  end
end