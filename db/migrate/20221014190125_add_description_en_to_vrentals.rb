class AddDescriptionEnToVrentals < ActiveRecord::Migration[7.0]
  def change
    add_column :vrentals, :description_en, :text
  end
end
