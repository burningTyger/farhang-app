Sequel.migration do
  change do
    create_table(:lemmas) do
      primary_key :id
      String :lemma, :null=>false
      String :slug, :null=>false
    end

    create_table(:translations) do
      primary_key :id
      String :source, :null=>false
      String :target, :null=>false
      foreign_key :lemma_id, :lemmas
    end
  end
end
