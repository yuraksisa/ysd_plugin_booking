module Sinatra
  module BookingHelpers
    
    def request_catalog

        catalog =  if params[:booking_catalog_code]
                      ::Yito::Model::Booking::BookingCatalog.get(params[:booking_catalog_code])
                   else
                      code = ::SystemConfiguration::Variable.get_value('booking.default_booking_catalog.code', nil)
                      ::Yito::Model::Booking::BookingCatalog.get(code)
                   end 
        
        unless catalog 
          catalog = ::Yito::Model::Booking::BookingCatalog.first
        end 

        return catalog

    end

    #
    # Get the booking catalog template
    # 
    #   - From the parameters
    #   - From the default template
    #   - The first catalog
    # 
    def catalog_template(catalog=nil)
    
        booking_js = if catalog
                       ContentManagerSystem::Template.find_by_name(catalog.rates_template_code)
                     else
                       ContentManagerSystem::Template.find_by_name('booking_js')
                     end
    end

  end
end
