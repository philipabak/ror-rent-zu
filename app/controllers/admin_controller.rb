require 'will_paginate/array'
class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin
  
  def index
  end

  def listings
    @listings = Residential.search(params[:query]).to_a
    @result_count = @listings.count
    @listings = @listings.paginate(page: params[:page], per_page: 25)
  end

  def edit_listing
    @listing = params[:class_name].titleize.constantize.where(id: params[:id]).first if params[:id] && params[:class_name]
    redirect_to :back, alert: "Could not find the listing" unless @listing
  end
  
  def update_listing
    @listing = params[:class_name].titleize.constantize.where(id: params[:id]).first if params[:id] && params[:class_name]
    @listing.assign_attributes listing_params
    @listing.fields_to_show = params[:fields_to_show]
    @listing.save
    redirect_to listing_path(@listing)
  end
  
  def destroy_listing
    @listing = params[:class_name].titleize.constantize.where(id: params[:id]).first if params[:id] && params[:class_name]
    redirect_to :back, alert: "Could not find the listing" unless @listing
    @listing.soft_delete
    redirect_to admin_listings_path, notice: "Listing has been deleted. Please refresh the page if the listing is still visible."
  end
  
  private
  
  def verify_admin
    redirect_to root_path, alert: "You're not an admin." and return unless current_user.admin?
  end
  
  def listing_params
    if params[:residential].present?
      required_param = :residential
    end
    params.require(required_param).permit!
  end
end
