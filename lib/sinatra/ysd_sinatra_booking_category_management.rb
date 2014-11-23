module Sinatra
  module YitoExtension
    module BookingCategoryManagement

      def self.registered(app)
        #
        # Booking categories page
        #
        app.get '/admin/booking/booking-categories/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          load_em_page :booking_categories_management, :bookingcategory, false

        end

      end

    end
  end
end
