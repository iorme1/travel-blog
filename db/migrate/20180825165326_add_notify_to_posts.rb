class AddNotifyToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :notify, :boolean
  end
end
