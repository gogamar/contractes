class AddDownPaymentToContracts < ActiveRecord::Migration[7.0]
  def change
    add_column :contracts, :down_payment, :float
  end
end
