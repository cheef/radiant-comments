begin
  require_dependency 'application_controller'
rescue MissingSourceFile
  require_dependency 'application'
end

class CommentsExtension < Radiant::Extension
  version "0.0.6"
  description "Adds blog-like comments and comment functionality to pages."
  url "http://github.com/saturnflyer/radiant-comments"
  
  define_routes do |map|                
    map.with_options(:controller => 'admin/comments') do |comments| 
      comments.destroy_unapproved_comments '/admin/comments/unapproved/destroy', :action => 'destroy_unapproved', :conditions => {:method => :delete}
      comments.connect 'admin/comments/:status', :status => /all|approved|unapproved/, :conditions => { :method => :get }
      comments.connect 'admin/comments/:status.:format'
      comments.connect 'admin/pages/:page_id/comments/:status.:format'
      comments.connect 'admin/pages/:page_id/comments/all.:format'
      
      comments.resources :comments, :path_prefix => "/admin", :name_prefix => "admin_", :member => {:approve => :get, :unapprove => :get}
      comments.admin_page_comments 'admin/pages/:page_id/comments/:action'
      comments.admin_page_comment 'admin/pages/:page_id/comments/:id/:action'
    end
    # This needs to be last, otherwise it hoses the admin routes.
    map.resources :comments, :name_prefix => "page_", :path_prefix => "*url", :controller => "comments"
  end
  
  def activate
    require 'csv_extensions'
    Page.send :include, CommentTags
    Page.send :include, Commentable
    Comment
    
    if admin.respond_to? :page
      admin.page.edit.add :parts_bottom, "edit_comments_enabled", :before => "edit_timestamp"
      admin.page.index.add :sitemap_head, "index_head_view_comments"
      admin.page.index.add :node, "index_view_comments"
    end
    
    admin.tabs.add "Comments", "/admin/comments/unapproved", :visibility => [:all]
  end
  
  def deactivate
  end
  
end
