class Sync
  def self.load_location_file
    File.open("public/full_data.json", 'w') do |file|
      file.write Listing.select("id", "latitude", "longitude").all.to_json
    end
  end

  def self.load_full_vow_set
    client = Rets::Client.new({
      login_url: 'http://rets.torontomls.net:6103/rets-treb3pv/server/login',
      username: 'V15ewy',
      password: 'Vm$5543',
      version: 'RETS/1.7'
    })
    client.login
    File.delete("public/full_vow_res_set.json") if File.exist?("public/full_vow_res_set.json")
    File.open("public/full_vow_res_set.json", 'w') do |file|
      res = client.find(:all, search_type: 'Property', class: 'ResidentialProperty', :query => "(status=A)")
      file.write res
      Sync.store_listing_data(res, "Residential", "vow")
    end
    File.delete("public/full_vow_condo_set.json") if File.exist?("public/full_vow_condo_set.json")
    File.open("public/full_vow_condo_set.json", 'w') do |file|
      res = client.find(:all, search_type: 'Property', class: 'CondoProperty', :query => "(status=A)")
      file.write res
      Sync.store_listing_data(res, "Condo", "vow")
    end
  end

  def self.load_full_idx_set
    client = Rets::Client.new({
      login_url: 'http://rets.torontomls.net:6103/rets-treb3pv/server/login',
      username: 'D14rta',
      password: 'Fc$2719',
      version: 'RETS/1.7'
    })
    client.login
    # File.delete("public/full_idx_res_set.json") if File.exist?("public/full_idx_res_set.json")
    # File.open("public/full_idx_res_set.json", 'w') do |file|
    #   res = client.find(:all, search_type: 'Property', class: 'ResidentialProperty', :query => "(status=A)")
    #   file.write res
    #   Sync.store_listing_data(res, "Residential", "idx")
    # end
    File.delete("public/full_idx_condo_set.json") if File.exist?("public/full_idx_condo_set.json")
    File.open("public/full_idx_condo_set.json", 'w') do |file|
      res = client.find(:all, search_type: 'Property', class: 'CondoProperty', :query => "(status=A)")
      file.write res
      Sync.store_listing_data(res, "Condo", "idx")
    end
  end


  def self.sync_full_set listing_class, listing_type
    client = Rets::Client.new({
        login_url: 'http://rets.torontomls.net:6103/rets-treb3pv/server/login',
        username: 'D14rta',
        password: 'Fc$2719',
        version: 'RETS/1.7'
      })

    begin
      client.login
      propertyList = client.find(:all, search_type: 'Property', class: 'ResidentialProperty', :query => '(status=A)')
      #propertyList = client.find(:all, search_type: 'Property', class: listing_class, :query => "(timestamp_sql=2015-01-27T00:00:00+)", limit: 1)

      File.open("public/alldata.txt", 'w') do |file|
        file.write propertyList
      end
      puts "\nReceived Data - count: #{propertyList.count}\n"
      Sync.store_residential_data(propertyList, client, listing_type)
    rescue => e
      puts "\nError....#{e}\n"
    end
  end

   def self.store_listing_data(property_hash, listing_type, visibility)
     property_hash.each_with_index do |row, i|
       begin
         puts "\nStart Listing: #{i+1}"
           new_hash = row.each_with_object({}) do |(k, v), h|
             if Listing.column_names.include? k.downcase
               h[k.downcase] = v
             end
           end
           existing = Listing.where(ml_num: new_hash["ml_num"]).first
           if existing.present? && existing.visibility == "vow"
             existing.update_attributes(visibility: "idx")
           elsif existing.nil?
             r = Listing.create!(new_hash.merge({visibility: visibility, listing_type: listing_type}))
           end
         puts "\nFinish Listing: #{i+1}"
       rescue
         puts "\nstore_residential_data failed for record #{row}\n"
       end
     end
   end

   def self.test
     client = Rets::Client.new({
         login_url: 'http://rets.torontomls.net:6103/rets-treb3pv/server/login',
         username: 'D14rta',
         password: 'Fc$2719',
         version: 'RETS/1.7'
       })
      client.login
      File.open("public/latest_alldata.json", 'w') do |file|
        res = client.find(:all, search_type: 'Property', class: 'ResidentialProperty', :query => "(status='A')")
        file.write res
      end
   end

   def self.store_all_vow_photos
     client = Rets::Client.new({
       login_url: 'http://rets.torontomls.net:6103/rets-treb3pv/server/login',
       username: 'V15ewy',
       password: 'Vm$5543',
       version: 'RETS/1.7'
     })
     client.login
     i = 0
     Listing.where(visibility: "vow").each do |listing|
       next if listing.listing_images.present?
       puts "\nPhotos for listing #{listing.id}\n"
       begin
         photos = client.objects '*', {
           resource: 'Property',
           object_type: 'Photo',
           resource_id: listing.ml_num
         }

         photos.each_with_index do |data, index|
           begin
             s3 = AWS::S3.new
             object = s3.buckets['zumin'].objects["listing_photos/listing_#{listing.id}_#{index}.jpg"]
             response = object.write(data.body, acl: :public_read)
             listing.listing_images.create(image_src: "http://zumin.s3.amazonaws.com/listing_photos/listing_#{listing.id}_#{index}.jpg")
             i += 1
             puts "#{response}"
             puts "count: #{i}"
           rescue
             puts "File upload failed. #{listing.id}"
           end
         end
       rescue
         puts "store_photos failed. #{listing.id}"
       end
     end
   end

   def self.store_all_idx_photos
     client = Rets::Client.new({
       login_url: 'http://rets.torontomls.net:6103/rets-treb3pv/server/login',
       username: 'D14rta',
       password: 'Fc$2719',
       version: 'RETS/1.7'
     })
     client.login
     i = 0
     Listing.where(visibility: "idx").each do |listing|
       next if listing.listing_images.present?
       puts "\nPhotos for listing #{listing.id}\n"
       begin
         photos = client.objects '*', {
           resource: 'Property',
           object_type: 'Photo',
           resource_id: listing.ml_num
         }

         photos.each_with_index do |data, index|
           begin
             s3 = AWS::S3.new
             object = s3.buckets['zumin'].objects["listing_photos/listing_#{listing.id}_#{index}.jpg"]
             response = object.write(data.body, acl: :public_read)
             listing.listing_images.create(image_src: "http://zumin.s3.amazonaws.com/listing_photos/listing_#{listing.id}_#{index}.jpg")
             i += 1
             puts "#{response}"
             puts "count: #{i}"
           rescue
             puts "File upload failed. #{listing.id}"
           end
         end
       rescue
         puts "store_photos failed. #{listing.id}"
       end
     end
   end
end