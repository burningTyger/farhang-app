FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "john#{n}@doe.com" }
    password 'secret'
    password_confirmation 'secret'
    roles [:user]
  end

  factory :lemma do |l|
    l.lemma 'das_schweigende_lemma'
  end

  sequence :lemma do |n|
    "lemma_#{n}"
  end

  sequence :translation_s do |n|
    "source_#{n}"
  end

  sequence :translation_t do |n|
    "target_#{n}"
  end

  factory :translation do |t|
    t.source 'lemmatologie!'
    t.target 'warum nicht?'
  end
end

