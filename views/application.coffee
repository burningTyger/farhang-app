$(document).ready ->
  $("#searchform").autocomplete
    source: "/lemmas/autocomplete"
    autoFocus: true
    select: (event, ui) ->
      $("#searchform").val ui.item.label
      $("#search").submit()

  $("#lemma_input").change ->
    str = $(this).val()
    $("#translationSource_0").val(str)
    
  $("#dialog").dialog
    autoOpen: false
    height: 300
    width: 750
    modal: true
    buttons:
      "Lemma anlegen": ->
        $.ajax "/lemma",
          data: $("#lemmaForm").serialize(),
          type: 'POST',
          success: (data) ->
            $("#lemmaList").append('<div id=newLemma></div>')
            $("#newLemma").hide().html(data).fadeIn('slow')
          error: ->
            alert('Ein Fehler ist aufgetreten. Bitte Eintrag korrigieren.')
        $(this).dialog "close"
      
      "Abbrechen": ->
        $(this).dialog "close"

  $('#searchform').focus()
