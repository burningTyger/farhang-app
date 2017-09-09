Sequel.migration do
  change do
    alter_table(:lemmas) do
      add_index [:lemma], unique: true
    end
  end
end
