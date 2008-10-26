class Newsletter < ActiveRecord::Base

  # Album creator
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"

  # Validations
  validates_presence_of :title, :message => "nem lehet üres"
  
  # State Machine Definition
  include AASM
  
  aasm_initial_state :draft
  
  aasm_state :draft
  aasm_state :pending
  aasm_state :public
  aasm_state :expired
  aasm_state :deleted
  
  # Drafting a Newsletter
  aasm_event :draft do
    transitions :to => :draft, :from => [:pending, :public, :expired, :deleted]
  end
  
  # Reviewing a Newsletter
  aasm_event :review do
    transitions :to => :pending, :from => [:draft]
  end
  
  # Publishing a Newsletter
  aasm_event :publish do
    transitions :to => :public, :from => [:draft, :pending]
  end
  
  # Expiring a Newsletter
  aasm_event :expire do
    transitions :to => :expired, :from => [:public]
  end

  # Deleting a Newsletter
  aasm_event :delete do
    transitions :to => :deleted, :from => [:draft, :public, :expired, :pending]
  end

  def expiry_date?
    expires_at == nil ? false : true
  end
  
  def publication_date?
    published_at == nil ? false : true
  end
  
  def last_editor!( user )
    update_attribute( :last_editor_name, user.realname )
  end
  
  def banner_magnum
    images.find(:first)
  end
  
  def banner_magnum_url
    b = banner_magnum
    b.photo.url if b
  end
  
end
