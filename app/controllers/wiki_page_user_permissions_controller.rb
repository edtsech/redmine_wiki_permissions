class WikiPageUserPermissionsController < ApplicationController
  unloadable
  
  def asd
  end
  
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
    
    #@wiki_page_user_permission = WikiPageUserPermission.find(params[:id])
    #if @WikiPageUserPermission.update_attributes(params[:post])
    #  flash[:notice] = "Successfully updated post."
    #  redirect_to :controller => 'wiki', :action => "permissions"
    #else
    #  render :action => 'edit'
    #end
  end
end