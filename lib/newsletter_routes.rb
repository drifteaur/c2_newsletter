module NewsletterRoutes
  def add(map)
    map.namespace( :admin ) do |admin|
      admin.resources :newsletters, 
                        :member => {  :associated => :get, 
                                      :publish => :post,
                                      :draft => :post,
                                      :review => :post,
                                      :search => :any,
                                      :add => :any,
                                      :remove => :any,
                                      :preview => :get }
      end
  end

  module_function :add
end