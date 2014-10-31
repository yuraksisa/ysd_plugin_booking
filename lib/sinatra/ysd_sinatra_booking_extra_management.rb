module Sinatra
  module YitoExtension
    module BookingExtraManagement

      def self.registered(app)

        #
        # Factor definition page
        #
        app.get '/admin/booking-extras/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          locals = {:booking_extras_page_size => 20}
          load_em_page :booking_extras_management, :bookingextra, false, :locals => locals

        end

      end

    end
  end
end