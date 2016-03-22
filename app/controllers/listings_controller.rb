require 'will_paginate/array'
class ListingsController < ApplicationController
  respond_to :html, :json

  def show
    @listing = Listing.where(id: params[:id]).first
    @page_title = @listing.full_address
    respond_to do |format|
      format.html {
        impressionist(@listing, "", {unique: [:ip_address]})
      }
      format.json {
        ahoy.track "Started Viewing listing", title: @page_title, id: @listing.id, class_name: @listing.class_name if logged_in?
        render json: @listing.show_json
      }
    end
  end

  def leave_page
    @listing = params[:class_name].constantize.where(id: params[:id]).first
    ahoy.track "Viewed listing", id: params[:id], class_name: params[:class_name], title: @listing.full_address, time_spent: ((DateTime.now - current_user.ahoy_events.last.try(:time).try(:to_datetime)) * 24 * 60 * 60).to_i if logged_in?
    respond_to do |format|
      format.js { render nothing: true}
    end
  end

  def map_data
    respond_to do |format|
      format.json {
        @listings = Listing.select('id, latitude, longitude')
        @listings = @listings.paginate(page: params[:page], per_page: params[:per_page])
        render json: @listings
      }
    end
  end

  def request_info
    listing = Listing.where(id: params[:id]).first
    render nothing: true unless listing
    lead_params = {
      first_name: params[:request][:first_name],
      last_name: params[:request][:last_name],
      phone: params[:request][:phone_number],
      email: params[:request][:email],
      source: URI(request.referer).path,
      requested_info: listing.title
    }
    Crm::Lead.delay.send_to_crm lead_params
    render nothing: true
  end

  def create_lead
    lead_params = {
      first_name: params[:lead][:first_name],
      last_name: params[:lead][:last_name],
      phone: params[:lead][:phone_number],
      email: params[:lead][:email],
      source: URI(request.referer).path,
      listing_info_lead_is: params[:lead][:lead_is]
    }
    Crm::Lead.delay.send_to_crm lead_params
    render nothing: true
  end

  def index
    if params[:autocomplete_form].present?
      params[:province] = params[:administrative_area_level_1]
      params[:city] = params[:locality]
      params[:street] = params[:route]
    end

    location_search = params[:province].present? || params[:city].present? || params[:street].present?
    respond_to do |format|
      format.html {
        @page_title = "Search Results"
        if location_search || params[:query].present?
          @page_title += " - "
          search_params = []
          [:province, :city, :street, :query].each do |key|
            search_params << params[key] if params[key].present?
          end
          @page_title += search_params.join(", ")
        end
      }
      format.json {
        if logged_in? && params[:page] == "1" && params[:notrack].nil?
          ahoy.track "Searched", query: params[:query] if params[:query].present?
          ahoy.track "Advanced Search", search_attributes: JSON.parse(params[:custom_search]) if params[:custom_search].present?
          ahoy.track "Searched Location", location: params.except!(*[:action, :controller, :format, :page]) if location_search
        end
        render json: Listing.where(id: params[:ids]).as_json(only: ['id', 'addr', 'municipality', 'county', 'zip', 'lp_dol', 'ml_num', 'type_own1_out', 'latitude', 'longitude', 'br', 'bath_tot', 'visibility']) and return if params[:ids].present?
        custom_search = params[:custom_search].present? ? JSON.parse(params[:custom_search]) : {}
        custom_search["listing_type"] = params[:listing_type] if params[:listing_type].present?
        if location_search
          custom_search["county"] = params[:province] if params[:province].present?
          custom_search["municipality"] = params[:city] if params[:city].present?
          custom_search["st"] = params[:street] if params[:street].present?
          params[:query] = ""
        end
        @listings = Listing.search(params[:query] || "", custom_search).to_a
        full_count = @listings.count
        render json: [{count: full_count}] and return if params[:count_only] == "1"
        render json: @listings.as_json(only: ['id']) and return if params[:ids_only] == "1"
        @listings = @listings.paginate(page: params[:page], per_page: params[:per_page] || 12) unless params[:paginate] == "0"
        render json: @listings.as_json(only: ['_type', 'id', 'addr', 'municipality', 'county', 'zip', 'lp_dol', 'ml_num', 'type_own1_out', 'latitude', 'longitude', 'br', 'bath_tot', 'visibility'], methods: ["_type", "image_count"]) << {count: full_count}
      }
    end
  end
end
