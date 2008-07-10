class C2NewsletterGenerator < Rails::Generator::Base 
  def manifest 
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate' 
    end 
  end
  
  def file_name
    "add_c2_newsletter"
  end
end
