module Sinatra
  module YitoExtension
    module BookingCustomers

      def self.registered(app)

        #
        # Booking customers search
        #
        app.get '/admin/booking/customers/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          load_page(:booking_customers)

        end

        #
        # Booking customers search
        #
        app.post '/admin/booking/customers/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          @item_count, @bookings = BookingDataSystem::Booking.customer_search(params[:search],{})
          
          load_page(:booking_customers)

        end

      end

    end
  end
end