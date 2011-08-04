lemmaAdd = (x) -> alert "#{x} hinzugefügt"
lemmaRemove = (x) -> alert "#{x} gelöscht"
$(document).ready ->
  $("input[id^='tags_']").each ->
    $(this).tagsInput
      height : ''
      width : ''
      interactive : true
      defaultText : '+ Lemma'
      removeWithBackspace : true
      placeholderColor : '#666666'
      delimiter : ' '
      onAddTag : lemmaAdd
      onRemoveTag : lemmaRemove
