module Sinatra
  module YitoExtension
    module BookingRentalLocationsManagement

      def self.registered(app)

        #
        # Pickup/return places
        #
        app.get '/admin/booking/rental-locations/?*', :allowed_usergroups => ['booking_manager','staff'] do

          locals = {:booking_rental_locations => 20}
          load_em_page :booking_rental_locations,
                       :booking_rental_location, false, :locals => locals

        end

      end

    end
  end
end