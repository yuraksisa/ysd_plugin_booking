module Sinatra
  module YitoExtension
    module BookingCategoryOfferManagement

      def self.registered(app)

        #
        # Factor definition page
        #
        app.get '/admin/booking/offers/?*', :allowed_usergroups => ['booking_manager', 'rates_manager', 'staff'] do

          locals = {:discount_page_size => 20}
          load_em_page :booking_category_offers_management, nil, false, :locals => locals

        end

      end

    end
  end
end