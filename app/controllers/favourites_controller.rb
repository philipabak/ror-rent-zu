class FavouritesController < ApplicationController
  def create
    respond_to do |format|
      format.json {
        if user_signed_in?
          f = current_user.favourites.create! favourite_params
          render json: f
        else
          render json: { error: "Cannot create favourite" }
        end
      }
    end
  end

  def index
    respond_to do |format|
      format.html { @page_title = "My Favourites" }
      format.json {
        render json: current_user.favourites.collect(&:favouriteable)
      }
    end
  end

  private

  def favourite_params
    params.require(:favourite).permit(:user_id, :favouriteable_type, :favouriteable_id)
  end
end
