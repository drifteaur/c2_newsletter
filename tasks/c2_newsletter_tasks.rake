# =============================================================================
# A set of rake tasks for invoking the newsletter utility.
# =============================================================================
#
# USAGE: rake newsletter:send_mail ID="1" RAILS_ENV="production"
#

namespace :newsletter do

	  desc "Sends newsletter to users which are subscribed. Pass ID=\":newsletter_id\""
	  task :send_mail => :environment do

		  #suppress(ActiveRecord::StatementInvalid) do
		  #  ActiveRecord::Base.connection.execute 'SET NAMES latin1'
		  #end
	  	
	  	newsletter = Newsletter.find( ENV['ID'], :conditions => ["aasm_state = 'public'"] )
			users = User.find(:all, :select => "id,email", :conditions => ["newsletter = 1"] )
			#users = User.find( :all, :conditions => ["newsletter = 1 AND id = 2"] )
			user_count = users.size
			# sleep time in seconds
			waiting = 0.1
			
			# count the successful deliveries
			success = 0
			
			puts "==== Starting delivery of #{user_count} e-mails  ========"
			users.each do |user|
				begin
					if NewsletterMailer.deliver_newsletter( newsletter, user.email, newsletter.title, 'hg@hg.hu' )
						success += 1
						puts ""
						puts "==== Email sent: No. #{success} of #{user_count} ======== Delivery speed: #{waiting} e-mail / sec"
					end
				rescue Exception => e
					puts "==== Email delivery error:  of #{user.email} #{e.message}"
				end
				sleep waiting
			end
      
      newsletter.update_attribute(:emails_sent, user_count)
       
      
			puts "==== Delivery finished: #{success} of #{user_count} e-mails has been sent  ========"
			puts ""
		end
  
end
