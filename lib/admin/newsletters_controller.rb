class Admin::NewslettersController < ApplicationController

	layout 'admin'

  # Filters
  before_filter :login_required
  before_filter { |c| c.authorize( 1,2,3 ) }
  before_filter :find_newsletter, :except => [ :index, :new, :create ]
  before_filter :build_search, :only => [ :index ]
  before_filter :find_authors, :only => [ :index ]

  # Invalid Record
  #rescue_from ActiveRecord::RecordInvalid do |exception|
  #  if exception.record.new_record?
  #    render :action => :new
  #  else
  #    render :action => :edit
  #  end
  #end

  # Main action for the Newsletters controller. It collects the appropriate newsletter objects for display.
  # Uses pagination.
  #
  def index
  	@newsletters = Newsletter.paginate :order => "created_at DESC", 
  	                                   :conditions => @conditions,  
  	                                   :page => params[:page], :per_page => 10
  end

  # This action is called when creating a new newsletter. It instantiates an empty newsletter object and renders the appropriate parital (new.html.erb).
  # If a new poll created with a title, then that title is assigned into the new object for convenience.
  #
  def new
  	@newsletter = Newsletter.new
  	flash[:notice] = _('Ez a hírlevél még nincs elmentve. Ha a későbbiekben folytatni akarod a munkát ezen a hírlevélen, meg kell adnod a kötelező adatokat és el kell mentened a hírlevelet.')
  end

  # Alias for :edit action, since we don't use a different show functionality. It's here because of CURD compatibility.
  #
  def show
    render :action => "edit"
  end

  # This action is called when editing an already existing newsletter. Uses the same form as :new, but renders it differently, due to
  # @newsletter.new_record? will be false. See <tt>/views/admin/newsletters/_form.html.erb</tt> and it's partials for specifics.
  #
  def edit
  end
  
  # Sub action for the main newsletter editor interface for managing any related content a newsletter might have.
  # See <tt>Document Associations</tt> for more information.
  #
  def associated
  end
  
  # Action for creating a new newsletter entry. Builds the new newsletter based on the incoming parameters and sets the author to the +current_user+.
  # If the newsletter saved successfully, it will redirect to +:edit+, otherwise it renders +:new+ again with the proper error messages.
  #
  def create
    @newsletter = Newsletter.new(params[:newsletter])
    
    # Can't be in model, because newsletter.rb loads as a plugin as well as the has_permalink plugin.
    # It's a load order errror.
    @newsletter.permalink = @newsletter.title.to_permalink
    
    @newsletter.author_id = current_user.id
    if @newsletter.save
      @newsletter.last_editor!( current_user )
      redirect_to edit_admin_newsletter_url(@newsletter)
    else
      render :action => :new
    end
  end

  # Action for updating an already existing newsletter entry. If the newsletter is updated successfully, there will be a redirect to +:edit+ with a +:notice+.
  # otherwise it will only re-render +:edit+ with error messages.
  #
  def update
    newsletter_parameters = params[:newsletter]
    
    # Set page publication time, if any
    options = {}
    unless params[:have_publish_time]
      newsletter_parameters.each do |key, val|
        newsletter_parameters.delete(key) if key.include?("published_at")
      end
    end
    
    # Set page expiration, if any
    unless params[:newsletter][:can_expire] == "1" || params[:newsletter][:can_expire] == "on"
      newsletter_parameters.each do |key, val|
        newsletter_parameters.delete(key) if key.include?("expires_at")
      end
    end
    
    # Merge the options back and update the poll
    newsletter_parameters.merge!( options )
		
  	if @newsletter.update_attributes( params[:newsletter] )
  	  @newsletter.last_editor!( current_user )
  	  flash[:notice] = _('A hírlevelet elmentettem, a változtatásaid rögzítésre kerültek.')
  	  redirect_to :back
  	else
  	  render :action => params[:render_action] || :edit
  	end
  end

  # Destroys a newsletter entry and redirects to the newsletter listings wether the destroy operation was successful or not.
  #
  def destroy
  	@newsletter.delete!
  	redirect_to admin_newsletters_url
  end
  
  def publish
  	@newsletter.publish!
  	@newsletter.update_attribute( :published_at, Time.now ) unless @newsletter.published_at
  	redirect_to :back
  end

  def draft
  	@newsletter.draft!
  	redirect_to :back
  end
  
  def review
  	@newsletter.review!
  	redirect_to :back
  end 
  
	# Associates an element to the newsletter object.
  def add
  	@element = params[:element][:type].constantize.find( params[:element][:id])
  	@newsletter.elements << @element if @element && !@newsletter.elements.include?(@element)
  end

	# Removes an object from the newsletter associates.
  def remove
  	@element = params[:element][:type].constantize.find( params[:element][:id] )
  	@newsletter.elements.delete(@element) if @element
  	render :action => "add"
  end
  
  # Searches for an object by keyword in the associateds.
  def search
  	phrase = "%#{params[:phrase]}%"
  	@id = "browser_#{params[:type].pluralize}"
  	@collection = params[:type].camelize.constantize.find(:all, :conditions => ["title LIKE ?", phrase], :limit => 50 )
  	render :layout => false
  end
  
  def preview
    render :layout => THEME["layouts"]["hirlevel"]
  end
  
  def send_mail
    if request.post?
  	  recipients = params[:recipients].split(" ")
  	  flash[:notice] = "Teszt levél elküldve" if NewsletterMailer.deliver_newsletter( @newsletter, recipients, "Teszt levél", "info@hg.hu" )
  	end
	rescue
		render :nothing => true
  end
  
  protected

  # Request parameter based automatic finder. It loads the newsletter with the ID specified in +params[:id]+.
  # If a newsletter not found, it will raise a ActiveRecord::RecordNotFound exception.
  # 
  # === Examples
  #
  #   # Using this as a filter
  #   # before_filter :find_newsletter, :only => [:show, :edit, :update]
  #
  def find_newsletter
  	@newsletter = Newsletter.find( params[:id] )
  end
	
	def build_search
	  @conditions = [""]
	  @filters = {}
    statements = []
    unless params[:author].nil? || params[:author] == "all"
      statements << %(newsletters.author_id = ?)
      @conditions << params[:author]
    end
    unless params[:state].nil? || params[:state] == "all"
      @conditions << params[:state]
      statements << %(newsletters.state = ?)
    end
    unless params[:search].nil? || params[:search] == ""
      @conditions << %(%#{params[:search]}%)
      statements << %(newsletters.title LIKE ?)
    end
    @conditions[0] = statements.join(" AND ")
  
    @filters[:author_id] = params[:author] || "all"
    @filters[:state] = params[:state] || "all"
	end
	
	def find_authors
	  # Load registered authors
	  @authors = User.find(:all, :select => "id,realname", :order => "realname")
	  @authors.delete_if { |a| a.id == current_user.id }
	  @authors.map! {|a| [a.realname, a.id] }
	end
  
end
