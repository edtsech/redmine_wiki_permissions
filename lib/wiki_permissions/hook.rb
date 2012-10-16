module WikiPermissions
  class WikiPermissionsHook < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head, :partial => 'hooks/html_header_rwp'
    render_on :view_layouts_base_body_bottom, :partial => 'hooks/body_bottom_rwp'
  end
end
