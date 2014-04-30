module Sinatra
  module YitoExtension
    module BookingItemManagement

      def self.registered(app)
        #
        # Booking items page
        #
        app.get '/admin/booking-items/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          load_em_page :booking_items_management, :bookingitem, false

        end

      end

    end
  end
end
