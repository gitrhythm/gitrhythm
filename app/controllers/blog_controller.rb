# coding: utf-8
class BlogController < ApplicationController
  def index
    logger.debug("hogeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
    page = params["page"].to_i
    page = 1 if page < 1
    @entries = Blog.instance.entries(page)
    @title = 'blog gitrhythm.net'
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def entry
    @entry = Blog.instance.entry(params[:year], params[:month], params[:day], params[:slug])
    @title = @entry.title + ' - gitrhythm.net'
    render :nothing => true, :status => 404 unless @entry
  end
end
