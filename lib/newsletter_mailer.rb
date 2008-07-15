class NewsletterMailer < ActionMailer::Base 
	
	def newsletter( newsletter, recipients, subject, from )
		@subject = subject
		@recipients = recipients
		@from = from
		@body["newsletter"] = newsletter
		
		part :content_type => "text/html", :body => render_message("newsletter_html", :newsletter => newsletter)
		
		part "text/plain" do |p|
			p.body = render_message("newsletter_plain", :newsletter => newsletter)
			p.transfer_encoding = "base64"
		end
		
	end
	
end