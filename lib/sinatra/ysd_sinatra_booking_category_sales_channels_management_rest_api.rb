module Sinatra
  module YitoExtension
    module BookingCategorySalesChannelManagementRESTApi

      def self.registered(app)

        
        #
        # Set up the channels for a booking category
        # 
        app.post "/api/booking/booking-categories/:booking_category_code/channels", :allowed_usergroups => ['booking_manager','staff'] do
          
          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys!

          @booking_category = ::Yito::Model::Booking::BookingCategory.get(params[:booking_category_code])
          halt 404 unless @booking_category
          
          if data[:sales_channels] and data[:sales_channels].is_a?Array
            @booking_category.setup_sales_channels(data[:sales_channels])
            content_type :json
            @booking_category.sales_channels.to_json
          end
          
        end
        
      end

    end
  end
end