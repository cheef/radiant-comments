class Admin::CommentsController < ApplicationController

  def index
    @comments = load_comments
    respond_to do |format|
      format.html
      format.csv { send_data @comments.to_csv, :filename => "#{File.basename(request.request_uri)}", :type => 'text/csv' }
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    announce_comment_removed
    clear_single_page_cache(@comment)
    redirect_to :back
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_comments_path
  end

  def destroy_unapproved
    if Comment.unapproved.destroy_all
      flash[:notice] = t 'comments.noticies.remove_all_unapproved.success'
    else
      flash[:notice] = t 'comments.noticies.remove_all_unapproved.fail'
    end
    redirect_to :back
  end

  def edit
    @comment = Comment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_comments_path
  end

  def show
    redirect_to edit_admin_comment_path(params[:id])
  end

  def update
    @comment = Comment.find(params[:id])
    begin
      TextFilter.descendants.each do |filter|
        @comment.content_html = filter.filter(@comment.content) if filter.filter_name == @comment.filter_id
      end
      @comment.update_attributes!(params[:comment])
      clear_cache
      flash[:notice] = t 'comments.noticies.update.success'
      redirect_to :action => :index
    rescue Exception => e
      flash[:notice] = t 'comments.noticies.update.fail', :message => e.message
      render :action => :edit
    end
  end

  def enable
    @page = Page.find(params[:page_id])
    @page.enable_comments = true
    @page.save!
    clear_cache
    flash[:notice] = t 'comments.noticies.enable.success', :page_title => @page.title
    redirect_to admin_pages_url
  end

  def approve
    @comment = Comment.find(params[:id])
    begin
      @comment.approve!
    rescue Comment::AntispamWarning => e
      antispamnotice = t 'comments.noticies.antispam.warning', :warning => e.message
    end
    clear_single_page_cache(@comment)
    flash[:notice] = t 'comments.noticies.approve.success', :page_title => @comment.page.title, :antispamnotice => (antispamnotice ? " (#{antispamnotice})" : "")
    redirect_to :back
  end

  def unapprove
    @comment = Comment.find(params[:id])
    begin
      @comment.unapprove!
    rescue Comment::AntispamWarning => e
      antispamnotice = t 'comments.noticies.antispam.warning', :warning => e.message
    end
    clear_single_page_cache(@comment)
    flash[:notice] = t 'comments.noticies.unapprove.success', :page_title => @comment.page.title, :antispamnotice => (antispamnotice ? " (#{antispamnotice})" : "")
    redirect_to :back
  end


  protected

  def load_comments
    status_scope.paginate(:page => params[:page])
  end

  def status_scope
    case params[:status]
    when 'approved'
      base_scope.approved
    when 'unapproved'
      base_scope.unapproved
    else
      base_scope
    end
  end

  def base_scope
    @page = Page.find(params[:page_id]) if params[:page_id]
    @page ? @page.comments : Comment.recent
  end

  def announce_comment_removed
    flash[:notice] = t 'comments.noticies.remove.success'
  end

  def clear_cache
    if defined?(ResponseCache)
      ResponseCache.instance.clear
    else
      Radiant::Cache.clear
    end
  end

  def clear_single_page_cache(comment)
    if comment && comment.page
      clear_cache
    end
  end

end