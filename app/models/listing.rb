class Listing < ActiveRecord::Base
  include Listable

  include Tire::Model::Search
  include Tire::Model::Callbacks

  has_many :listing_images, as: :imageable
  has_many :favourites, as: :favouriteable
  is_impressionable

  geocoded_by :geocoding_address
  after_validation :geocode

  default_scope { where(deleted_at: nil) }

  mapping do
    indexes :county, index: :not_analyzed
    indexes :municipality, index: :not_analyzed
    indexes :st, index: :not_analyzed
    self.columns.reject{|c| %w(county municipality st).include?(c.name)}.each do |f|
      t = case f.type
      when :datetime
        :date
      when :text
        :string
      when :decimal
        :float
      else
        f.type
      end
      indexes f.name.to_sym, type: t
    end
  end

  def self.search(q_str, additional_attr={})
    tire.search do
      query { string q_str} if q_str.present?
      filter :missing, field: "deleted_at"

      filter :term, county: additional_attr["county"] if additional_attr["county"].present?
      filter :term, municipality: additional_attr["municipality"] if additional_attr["municipality"].present?
      filter :term, st: additional_attr["st"] if additional_attr["st"].present?
      filter :term, listing_type: additional_attr["listing_type"].downcase if additional_attr["listing_type"].present?

      if additional_attr["min_price"].present? && additional_attr["max_price"].present?
        filter :range, lp_dol: { gte: Listable.format_number(additional_attr["min_price"]), lte: Listable.format_number(additional_attr["max_price"]) }
      elsif additional_attr["min_price"].present?
        filter :range, lp_dol: { gte: Listable.format_number(additional_attr["min_price"]) }
      elsif additional_attr["max_price"].present?
        filter :range, lp_dol: { lte: Listable.format_number(additional_attr["max_price"]) }
      end
      if additional_attr["search_bath"].present?
        if additional_attr["search_bath"].include?("+")
          filter :range, bath_tot: { gte: Listable.format_number(additional_attr["search_bath"]) }
        else
          filter :term, bath_tot: Listable.format_number(additional_attr["search_bath"])
        end
      end
      if additional_attr["search_beds"].present?
        if additional_attr["search_beds"].include?("+")
          filter :range, br: { gte: Listable.format_number(additional_attr["search_beds"]) }
        else
          filter :term, br: Listable.format_number(additional_attr["search_beds"])
        end
      end
      size 50000
      fields {}
    end
  end
end