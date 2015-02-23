module Sinatra
  module YitoExtension
    module BookingCatalogManagement

      def self.registered(app)

        #
        # Catalogs
        #
        app.get '/admin/booking/catalog/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          default_catalog = ::SystemConfiguration::Variable.get_value('booking.default_booking_catalog.code', nil)
          locals = {:booking_catalogs_page_size => 20, :default_catalog => default_catalog}
          load_em_page :booking_catalogs_management, 
                       :booking_catalog, false, :locals => locals

        end

      end

    end
  end
end