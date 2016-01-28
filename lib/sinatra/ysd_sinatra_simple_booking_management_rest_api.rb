module Sinatra
  module YSD
    #
    # Sinatra extension to manage simple bookings
    #
    module SimpleBookingManagementRESTApi

      def self.registered(app)


        #
        # Get booking hourly occupation
        #
        app.get '/api/simple/booking/hourly-occupation' do

           date = DateTime.now
           if params[:date]
             date = DateTime.strptime(params[:date], '%Y-%m-%d')
           end

           data = BookingDataSystem::Booking.hourly_occupation(date)

           data.to_json

        end

      end

    end
  end
end