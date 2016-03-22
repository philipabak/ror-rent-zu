window.chunk = (arr, size) ->
  newArr = []
  i = 0
  while i < arr.length
    newArr.push arr.slice(i, i + size)
    i += size
  newArr

window.load_info_box = (id) ->
  $.ajax
    url: '/listings?ids=' + id
    type: 'GET'
    dataType: "json"
    success: (data, status, response) ->
      if($("body").data("signed-in") == false && data[0].visibility == 'vow')
        wrap_clas = 'media blur'
      else
        wrap_clas = 'media'
      html_str = "<a class='infobox-close' href='#' onclick='infobox.setOptions({visible:false});return false;'>x</a><div class='"+wrap_clas+"'><div class='media-left'><img src='http://zumin.s3.amazonaws.com/listing_photos/listing_"+id+"_0.jpg' onerror='this.onerror=null;this.src=\"/missing-image.png\";'></div><div class='media-body'><h4><a target='_self' href='/listings/"+id+"'>"+data[0].addr+", "+data[0].municipality+"</a></h4><p>$"+numberWithCommas(data[0].lp_dol)+"<br>"+data[0].br+" beds, "+data[0].bath_tot+" baths</p><div></div></div></div>"
      if($("body").data("signed-in") == false && data[0].visibility == 'vow')
        html_str += "<div class='overlay'>Sign in to view</div>"
      $('.custom-infobox').first().html html_str
    error: ->
      $('.custom-infobox').first().html "Something went wrong"

# window.load_map_data = () ->
  # unless localStorage.getItem('fully_loaded_map_data') == "true"
  #   a = 1
#    results_to_store = get_paginated_results([], 1)

# window.get_paginated_results = (all_results, page) ->
#   $.ajax
#     url: '/listings/map_data?per_page=1000&page=' + page
#     type: 'GET'
#     dataType: "json"
#     success: (data, status, response) ->
#       for d in data
#         all_results.push d
#       if data.length == 1000
#         get_paginated_results(all_results, page+1)
#       else
#         store_data all_results
#     error: ->
#       localStorage.setItem('fully_loaded_map_data', 'false')
#
# window.store_data = (results) ->
#   localStorage.setItem('full_map_data', JSON.stringify(results))
#   localStorage.setItem('fully_loaded_map_data', 'true')

window.setByWidthHeight = ->
  wh = $(window).width()
  nb = $('.navbar-header').width()
  nn = $('.navbar-nav').width()
  nr = $('.navbar-right').width()
  w = wh - nb - nn - nr - 43
  $('.navbar-form').width w
  $('.navbar-form').find('.form-control').width w - 165
  $('.banner').height $(window).height() - 90
  $('#menu-scroll').height $(window).height() - 110
  return

$ ->
  $(".home-autocomplete-field").geocomplete(details: "#home_detail_fields")
  $(".advanced-search-autocomplete-field").geocomplete(details: "#advanced_search_detail_fields")

  $(".navbar-autocomplete-field").geocomplete(details: "#navbar_detail_fields").bind "geocode:result", ->
    $("#navbar_detail_fields").submit()
  $(document).on 'click', '.custom_select', (e)->
    e.preventDefault()
    $($(this).data('target-field')).val($(this).data('target-value'))
    $($(this).data('target-btn')).html($(this).text())

  $(document).on 'click', '.radio_buttons_item', (e)->
    e.preventDefault()
    $(this).siblings('.active').removeClass('active')
    $(this).addClass('active')
    $($(this).data('target')).val($(this).data('value'))
    $($(this).data('target')).trigger('input')

  setByWidthHeight()
  $(window).resize ->
    setByWidthHeight()
    return
  $('.scroll-down').click (e) ->
    $('body,html').animate { scrollTop: $('#explore').offset().top - 75 }, 700
    e.preventDefault()
    return
  $('.slow-scroll').click (e) ->
    $('body,html').animate { scrollTop: $($(this).data("target")).offset().top - 50 }, 700
    e.preventDefault()
    return
  $('.menu-toggle').click (e) ->
    if $(this).hasClass('active')
      $('.nav-menu').removeClass 'show'
      $('body').removeClass 'nav-open'
      $(this).removeClass 'active'
    else
      $(this).addClass 'active'
      $('body').addClass 'nav-open'
      $('.nav-menu').addClass 'show'
    e.preventDefault()
    return
  $('#menu-scroll').nanoScroller sliderMaxHeight: 50
  $('[data-toggle="signup"]').click (e) ->
    $('#modal-login').modal 'hide'
    setTimeout (->
      $('#modal-signup').modal 'show'
      return
    ), 350
    e.preventDefault()
    return
  $('[data-toggle="login"]').click (e) ->
    $('#modal-signup').modal 'hide'
    setTimeout (->
      $('#modal-login').modal 'show'
      return
    ), 350
    e.preventDefault()
    return
  return

$ ->
  $('.selectpicker').selectpicker
    width: 150
  $('.selectpicker100').selectpicker
    width: 90

  $('.dropdown-toggle[data-id="search_beds_select"] .filter-option').html("Beds")
  $('.dropdown-toggle[data-id="search_baths_select"] .filter-option').html("Baths")

  $('.price-range-menu input, .price-range-menu li').on "click", (e)->
    e.stopPropagation()

  $('.min_price_list_item').on "click", ->
    $("#min_price_input").val $(this).data("price-value")

  $('.max_price_list_item').on "click", ->
    $("#max_price_input").val $(this).data("price-value")

  $(document).on "mouseover", ".house-media", ->
    loc = new Microsoft.Maps.Location $(this).data("lat"), $(this).data("long")
    if infobox
      infobox.setLocation loc
      infobox.setOptions
        visible: true
        htmlContent: "<div class='custom-infobox'><a class='infobox-close' href='#' onclick='infobox.setOptions({visible:false});return false;'>x</a>" + $(this).html() + "</div>"