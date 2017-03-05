module Sinatra
  module YitoExtension
    module BookingExtraManagement

      def self.registered(app)

        #
        # Factor definition page
        #
        app.get '/admin/booking/booking-extras/?*', :allowed_usergroups => ['booking_manager','staff'] do

          # TODO multi-tenant
          @show_translations = settings.multilanguage_site
          locals = {:booking_extras_page_size => 20}
          load_em_page :booking_extras_management, :bookingextra, false, :locals => locals

        end

      end

    end
  end
end