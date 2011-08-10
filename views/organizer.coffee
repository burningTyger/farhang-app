curry = (func, curryArgs...) -> (args...) -> func.apply this, curryArgs.concat args
$(document).ready ->
  lemmaAdd = (id, value) ->
    $.ajax "/translations/#{id}/lemmas",
      data: "lemma=#{value}"
      type: 'PUT'  
  
  $("input[id^='tags_']").each ->
    id = $(this).attr("id").replace("tags_","")
    $(this).tagsInput
      height: ''
      width: ''
      interactive: true
      defaultText: '+ Lemma'
      removeWithBackspace: true
      placeholderColor: '#666666'
      onAddTag: curry lemmaAdd, id
      onRemoveTag: curry lemmaAdd, id
      autocomplete_url: 'http://localhost:9292/organizer/autocomplete'
      autocomplete: 
        selectFirst: true
