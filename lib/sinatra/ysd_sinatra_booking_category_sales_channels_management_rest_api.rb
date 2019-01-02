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
          
          if data[:sales_channels] 
            sc = (data[:sales_channels].is_a?(Array) ? data[:sales_channels] : [data[:sales_channels]])
            @booking_category.setup_sales_channels(sc)
            content_type :json
            @booking_category.sales_channels.to_json
          end
          
        end

        #
        # Update 
        #
        app.put "/api/booking/booking-categories/:booking_category_code/channels/:sales_channel_id", allowed_usergroups: ['booking_manager','staff'] do

          @category_sales_channel = ::Yito::Model::Booking::BookingCategoriesSalesChannel.first(booking_category_code: params[:booking_category_code],
                                                                                                sales_channel_id: params[:sales_channel_id])
          halt 404 unless @category_sales_channel

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys!
          
          @category_sales_channel.attributes=data
          @category_sales_channel.save

          status 200
          content_type :json
          @category_sales_channel.to_json

        end  
        
      end

    end
  end
end