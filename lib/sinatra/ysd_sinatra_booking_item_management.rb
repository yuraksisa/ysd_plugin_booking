module Sinatra
  module YitoExtension
    module BookingItemManagement

      def self.registered(app)
        
        #
        # Booking items page
        #
        app.get '/admin/booking/booking-items/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          load_em_page :booking_items_management, :bookingitem, false

        end

        #
        # Products that belongs to a category
        #
        app.get '/admin/booking/stock/:category/?*', :allowed_usergroups => ['booking_manager','staff'] do

          @items = ::Yito::Model::Booking::BookingItem.all(conditions: {category_code: params[:category], active: true},
                                                           order: [:own_property.desc, :assignable.desc, :reference])
          load_page :booking_category_stock

        end



      end

    end
  end
end
