class AddSuppliersIndexes < ActiveRecord::Migration
  def up
    add_index :supplier_categories_suppliers, [:supplier_category_id, :supplier_id], name: 'supplier_index'
  end

  def down
    remove_index :supplier_categories_suppliers, :column => [:supplier_category_id, :supplier_id]
  end
end
