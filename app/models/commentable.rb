module Commentable
  def self.included(base)
    base.class_eval do
      has_many :comments, :dependent => :destroy, :order => "created_at ASC"
      has_many :approved_comments, :class_name => "Comment", :conditions => "comments.approved_at IS NOT NULL", :order => "created_at ASC"
      has_many :unapproved_comments, :class_name => "Comment", :conditions => "comments.approved_at IS NULL", :order => "created_at ASC"
      attr_accessor :last_comment
      attr_accessor :selected_comment
    end
  end
  
  def has_visible_comments?
    !(approved_comments.empty? && selected_comment.nil?)
  end
  
end
