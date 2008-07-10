# Include hook code here
require 'document'
require File.dirname(__FILE__) + '/lib/newsletter'


PLUGINS << { :name => "c2_newsletter", 
						 :url => "/admin/newsletters",
						 :title => "Hírlevelek", 
						 :description => "Hírlevelek adminisztrációja",
						 :view_path => "#{RAILS_ROOT}/vendor/plugins/calcium_newsletter/app/views/",
						 :route_module => "NewsletterRoutes",
						 :route_module_url => "#{RAILS_ROOT}/vendor/plugins/calcium_newsletter/lib/newsletter_routes.rb" }
