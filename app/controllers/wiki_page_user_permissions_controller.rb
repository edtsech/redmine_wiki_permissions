class WikiPageUserPermissionsController < ApplicationController
  def index
    @wiki_page_user_permissions = WikiPageUserPermission.all
  end
  
  def show
    @wiki_page_user_permission = WikiPageUserPermission.find(params[:id])
  end
  
  def new
    @wiki_page_user_permission = WikiPageUserPermission.new
  end
  
  def create
    @wiki_page_user_permission = WikiPageUserPermission.new(params[:wiki_page_user_permission])
    if @wiki_page_user_permission.save
      flash[:notice] = "Successfully created wiki page user permission."
      redirect_to @wiki_page_user_permission
    else
      render :action => 'new'
    end
  end
  
  def edit
    @wiki_page_user_permission = WikiPageUserPermission.find(params[:id])
  end
  
  def update
    @wiki_page_user_permission = WikiPageUserPermission.find(params[:id])
    if @wiki_page_user_permission.update_attributes(params[:wiki_page_user_permission])
      flash[:notice] = "Successfully updated wiki page user permission."
      redirect_to @wiki_page_user_permission
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @wiki_page_user_permission = WikiPageUserPermission.find(params[:id])
    @wiki_page_user_permission.destroy
    flash[:notice] = "Successfully destroyed wiki page user permission."
    redirect_to wiki_page_user_permissions_url
  end
end
