class AddC2Newsletter < ActiveRecord::Migration
  def self.up
    create_table :newsletters do |t|
    	
      # Foreign Keys
      t.references :author

      # Basic Content
      t.string :title, :null => false
      t.string :short_title, :permalink
      t.text :excerpt

      # Timestamps
      t.timestamp :created_at, :updated_at, :published_at, :expires_at
      
      # State
      t.string :state, :null => false, :default => "draft"

      # Counters & Options
      t.integer :can_expire, :emails_sent, :default => 0
    end
    
  end
  
  def self.down
    drop_table :newsletters
  end
end
