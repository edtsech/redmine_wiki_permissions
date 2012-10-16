ActionController::Routing::Routes.draw do |map|
  map.resources :projects do |project|
    project.wiki_permissions 'wiki/:id/permissions', :controller => 'wiki', :action => 'permissions'
    project.wiki_permissions 'wiki/:id/permissions/create', :controller => 'wiki', :action => 'create_wiki_page_user_permissions'
    project.wiki_permissions 'wiki/:id/permissions/update', :controller => 'wiki', :action => 'update_wiki_page_user_permissions'
    project.wiki_permissions 'wiki/:id/permissions/delete', :controller => 'wiki', :action => 'destroy_wiki_page_user_permissions'
  end
end
