# encoding: UTF-8
FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "john#{n}@doe.com" }
    password 'secret'
    password_confirmation 'secret'
    roles [:user]
  end

  factory :lemma do
    lemma 'Wörterbuch'
    translations { |translations| [ translations.association(:translation),
                                    translations.association(:translation)]}
    valid true

    trait :sequential_lemma do
      sequence(:lemma) {|n| "lemma#{n}" }
    end

    factory :multi_lemma, :traits => [:sequential_lemma]
  end

  factory :translation do
    source 'Lexikon'
    target 'فرهنگ'
  end
end

