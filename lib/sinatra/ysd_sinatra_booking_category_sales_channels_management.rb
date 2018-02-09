module Sinatra
  module YitoExtension
    module BookingCategorySalesChannelManagement

      def self.registered(app)

        #
        # Edit booking category - channel configuration
        #
        app.get "/admin/booking/booking-categories/:booking_category_code/channels/:sales_channel_id/?*", :allowed_usergroups => ['booking_manager','staff'] do

          @category_sales_channel = ::Yito::Model::Booking::BookingCategoriesSalesChannel.first(booking_category_code: params[:booking_category_code],
                                                                                                sales_channel_id: params[:sales_channel_id])
          halt 404 unless @category_sales_channel
          
          load_page :booking_category_sales_channels_edit


        end

        #
        # Get all the channels for a booking category
        #
        app.get "/admin/booking/booking-categories/:booking_category_code/channels", :allowed_usergroups => ['booking_manager','staff'] do
          
          @booking_category = ::Yito::Model::Booking::BookingCategory.get(params[:booking_category_code])
          halt 404 unless @booking_category # If not exists the booking category HALT

          # Get the channels
          @booking_category_channels = ::Yito::Model::Booking::BookingCategoriesSalesChannel.all(booking_category_code: params[:booking_category_code])

          load_page :booking_category_sales_channels_list

        end

        #
        # Set up the channels for a booking category
        #
        app.get "/admin/booking/booking-categories/:booking_category_code/setup-channels", :allowed_usergroups => ['booking_manager','staff'] do

          @booking_category = ::Yito::Model::Booking::BookingCategory.get(params[:booking_category_code])
          halt 404 unless @booking_category # If not exists the booking category HALT

          @booking_category_channels = ::Yito::Model::Booking::BookingCategoriesSalesChannel.all(booking_category_code: params[:booking_category_code])
          @channels = ::Yito::Model::SalesChannel::SalesChannel.all

          load_page :booking_category_sales_channels_setup

        end

      end
    end
  end
end