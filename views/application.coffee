$(document).ready ->
  $('input:text').focus()
  $("#searchform").autocomplete 
    source: "/lemmas/autocomplete"
    autoFocus: true
    select: (event, ui) ->
      $("#searchform").val ui.item.label
      $("#search").submit()
