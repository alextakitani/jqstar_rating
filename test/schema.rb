ActiveRecord::Schema.define(:version => 0) do
  
  create_table :ratings do |t|
      t.references :user
      t.references :rateable, :polymorphic => true
      t.decimal :value, :precision => 2, :scale => 2 
      t.string :dimension

      t.timestamps
    end
  
end