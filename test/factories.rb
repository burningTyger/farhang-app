Factory.define :lemma do |l|
  l.lemma 'das_schweigende_lemma'
end

Factory.sequence :lemma do |n|
  "lemma_#{n}"
end

Factory.sequence :translation_s do |n|
  "source_#{n}"
end

Factory.sequence :translation_t do |n|
  "target_#{n}"
end

Factory.define :translation do |t|
  t.source { Factory.next(:translation_s) }
  t.target { Factory.next(:translation_t) }
end
