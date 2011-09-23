curry = (func, curryArgs...) -> (args...) -> func.apply this, curryArgs.concat args
$(document).ready ->
  $(".pageButton").button()
  
  lemmaAdd = (translation_id, value) ->
    $.ajax "/lemma",
      data: "lemma=#{value}",
      type: 'GET',
      success: (data) ->
        $.ajax "/lemma/#{data.id}/translations",
          data: "translation_id=#{translation_id}",
          type: 'PUT'
  
  $("input[id^='tags_']").each ->
    translation_id = $(this).attr("id").replace("tags_","")
    $(this).tagsInput
      height: ''
      width: ''
      interactive: true
      defaultText: '+ Lemma'
      removeWithBackspace: true
      placeholderColor: '#666666'
      onAddTag: curry lemmaAdd, translation_id
      onRemoveTag: curry lemmaAdd, translation_id
      autocomplete_url: '/lemmas/autocomplete'
      autocomplete:
        autoFocus: true
