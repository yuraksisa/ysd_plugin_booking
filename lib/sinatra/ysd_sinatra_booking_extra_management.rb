module Sinatra
  module YitoExtension
    module BookingExtraManagement

      def self.registered(app)

        #
        # Factor definition page
        #
        app.get '/admin/booking/booking-extras/?*', :allowed_usergroups => ['booking_manager','staff'] do

          @show_translations = settings.multilanguage_site
          @booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:booking_extras_page_size => 20}
          load_em_page :booking_extras_management, :bookingextra, false, :locals => locals

        end

      end

    end
  end
end