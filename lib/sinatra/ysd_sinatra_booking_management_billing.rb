module Sinatra
  module YSD
    #
    # Sinatra extension to manage bookings
    #
    module BookingBilling

      def self.registered(app)

        #
        # Get the product billing for a year
        #
        app.get '/admin/booking/product-billing', :allowed_usergroups => ['booking_manager', 'staff'] do

          today = Date.today
          @year = params[:year].to_i == 0 ? today.year : params[:year].to_i
          @previous_year = @year - 1
          @next_year = @year + 1

          @data = BookingDataSystem::Booking.products_billing_summary_by_stock(@year)

          load_page :products_billing

        end

        #
        # Get the extras billing for a year
        #
        app.get '/admin/booking/extras-billing', :allowed_usergroups => ['booking_manager', 'staff'] do

          today = Date.today
          @year = params[:year].to_i == 0 ? today.year : params[:year].to_i
          @previous_year = @year - 1
          @next_year = @year + 1

          @data = BookingDataSystem::Booking.extras_billing_summary_by_extra(@year)

          load_page :extras_billing

        end

      end
    end
  end
end