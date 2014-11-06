module Sinatra
  module YitoExtension
    module BookingPickupReturnPlaceDefinitionsManagement

      def self.registered(app)

        #
        # Pickup/return places
        #
        app.get '/admin/booking-place-defs/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          locals = {:booking_pickup_return_place_defs => 20}
          load_em_page :booking_pickup_return_place_defs_management, 
                       :booking_pickup_return_place_defs, false, :locals => locals

        end

      end

    end
  end
end