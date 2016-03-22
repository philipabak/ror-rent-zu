app = angular.module("Zumin", ["ngResource", "ngtimeago"])

app.factory "Listing", ["$resource", ($resource) ->
  $resource("/listings/:id/:action.json", {id: "@id"}, {request_info: {method: "POST", params: {action: "request_info"}, isArray: false}, create_lead: {method: "POST", params: {action: "create_lead"}, isArray: false}})
]

app.factory "Favourite", ["$resource", ($resource) ->
  $resource("/favourites/:id.json", {id: "@id"})
]

app.controller 'ListingsCtrl', ['$scope', 'Listing', 'Favourite', ($scope, Listing, Favourite) ->
  $scope.Math = window.Math

  $scope.submit_request_form = ->
    $("#request_info_form").addClass('hide')
    $("#request_info_spinner").removeClass('hide')
    Listing.request_info({id: $scope.listing.id, request: $scope.request}).$promise.then ((data) ->
      $("#request_info_spinner").addClass('hide')
      $("#request_info_success").removeClass('hide')
      return
    ), (error) ->
      $("#request_info_spinner").addClass('hide')
      $("#request_info_error").removeClass('hide')
      return

  $scope.submit_new_lead_form = ->
    $("#create_lead_form").addClass('hide')
    $("#create_lead_spinner").removeClass('hide')
    Listing.create_lead({lead: $scope.lead}).$promise.then ((data) ->
      $("#create_lead_spinner").addClass('hide')
      $("#create_lead_success").removeClass('hide')
      return
    ), (error) ->
      $("#create_lead_spinner").addClass('hide')
      $("#create_lead_error").removeClass('hide')
      return

  $scope.loadListing = (id) ->
    $scope.listing = Listing.get({id:id}, ->
      $scope.related_listings = Listing.query({city: $scope.listing.city, notrack: 1}, ->
        $scope.related_listings.pop()
      )
      $scope.current_page = 1
    )

  $scope.load_related_listings = (page_num) ->
    if page_num > 0 && page_num < (($scope.listing.city_listing_count / 12) + 1)
      $scope.related_listings = Listing.query({city: $scope.listing.city, page: page_num, notrack: 1}, ->
        $scope.related_listings.pop()
      )
      $scope.current_page = page_num

  $scope.load_search_page = (search) ->
    search = JSON.parse search
    search["page"] = 1
    $scope.results = Listing.query(search, ->
      $scope.results_count = $scope.results.pop().count
      $scope.current_page = 1
      $scope.listings = chunk($scope.results, 4)
    )

  $scope.load_search_listings = (page_num, results_count, search) ->
    if page_num > 0 && page_num < ((results_count / 12) + 1)
      search = JSON.parse search
      search["page"] = page_num
      search["notrack"] = 1
      $scope.results = Listing.query(search, ->
        $scope.results_count = $scope.results.pop().count
        $scope.current_page = page_num
        $scope.listings = chunk($scope.results, 4)
      )

  $scope.add_favourite = (listing_type, listing_id) ->
    $scope.favourite = new Favourite()
    $scope.favourite.favouriteable_type = listing_type
    $scope.favourite.favouriteable_id = listing_id
    Favourite.save $scope.favourite, ->
      $("#add_to_favourites").replaceWith "Favourited!"
    , ->
      alert "Something went wrong! Please try again later."

  $scope.load_favourites = ->
    $scope.favourites = Favourite.query({}, ->
      $scope.listings = chunk($scope.favourites, 4)
    )

  $scope.toggle_search_results = (api_key, search) ->
    if $scope.map_displayed
      $("#map_results").hide()
      $("#search_results").show()
      $scope.map_displayed = false
    else
      $scope.map_loading = true
      $("#search_results").hide()
      $("#map_results").show()
      $('#map').gmap
        'credentials': api_key
        'center': new (Microsoft.Maps.Location)(43.75937314543584, -78.9841431640625)
        'zoom': 9
        'callback': ->
          window.mp = this
          self = this
          clusterLoaded(self.instance.map)
          unless $scope.all_results?
            search = JSON.parse search
            search["notrack"] = 1
            load_map_results(search, self.instance.map)
      $('#house-scroll-map').nanoScroller sliderMaxHeight: 50
      $('.map-container').height($(window).height() - 90)
      $('#house-scroll-map').height($(window).height() - 250)
      $scope.map_displayed = true

  load_map_results = (search, map) ->
    $scope.map_results_loading = true
    $.getJSON 'full_data.json', (data) ->
      local_storage_map_data = data
      search["paginate"] = 0
      search["ids_only"] = 1
      $scope.all_results = []
      Listing.query(search).$promise.then ((data) ->
        data.map (d) ->
          $scope.all_results.push local_storage_map_data[d.id] if local_storage_map_data[d.id]?
        window.greenLayer.SetData($scope.all_results)
        Microsoft.Maps.Events.addThrottledHandler(map, 'viewchangestart', reset_results, 250)
        Microsoft.Maps.Events.addThrottledHandler(map, 'viewchangeend', update_pin_listings, 250)
        update_pin_listings()
        return
      ), (error) ->
        alert "Something went wrong. Please reload the page."
        return

  reset_results = ->
    $scope.map_results_list = []
    $scope.map_results_loading = true
    $scope.map_loading = true
    $scope.$apply()

  update_pin_listings = ->
    $scope.results_to_show = []
    for res in $scope.all_results
      $scope.results_to_show.push(res) if mp.instance.map.getBounds().contains(new (Microsoft.Maps.Location)(res.latitude, res.longitude))
    $scope.map_results_page = 1
    c_ids = []
    for el in $scope.results_to_show[0..11]
      c_ids.push el.id
    $scope.map_results_list = Listing.query({"ids[]": c_ids}, ->
      $scope.map_results_loading = false
    )
    $scope.map_loading = false
    if !$scope.$$phase
      $scope.$apply()

  $scope.next_map_page = ->
    if ($scope.map_results_page * 12 < $scope.results_to_show.length)
      $scope.map_results_list = []
      $scope.map_results_loading = true
      $scope.map_results_page += 1
      c_ids = []
      for el in $scope.results_to_show[(($scope.map_results_page-1)*12)..(($scope.map_results_page*12)-1)]
        c_ids.push el.id
      $scope.map_results_list = Listing.query({"ids[]": c_ids}, ->
        $scope.map_results_loading = false
      )

  $scope.prev_map_page = ->
    if $scope.map_results_page > 1
      $scope.map_results_list = []
      $scope.map_results_loading = true
      $scope.map_results_page -= 1
      c_ids = []
      for el in $scope.results_to_show[(($scope.map_results_page-1)*12)..(($scope.map_results_page*12)-1)]
        c_ids.push el.id
      $scope.map_results_list = Listing.query({"ids[]": c_ids}, ->
        $scope.map_results_loading = false
      )
]