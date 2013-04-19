require 'json' unless defined?JSON
require 'ysd_md_booking' unless defined?BookingDataSystem::Booking

module Sinatra
  module YSD
    #
    # Sinatra extension to manage bookings
    #
    module BookingRESTApi

     def self.registered(app)

        #
        # Creates a booking
        #
        app.post '/confirm_booking/?' do
              
          request.body.rewind 
          data = JSON.parse request.body.read     
          
          booking_data = data['booking'].keep_if do |key, value| 
            BookingDataSystem::Booking.properties.field_map.keys.include?(key) or 
            BookingDataSystem::Booking.relationships.named?(key)
          end

          booking = BookingDataSystem::Booking.new(booking_data)
          booking.save
          
          if not booking.charges.empty?
            session[:booking_id] = booking.id
            session[:charge_id] = booking.charges.first.id
            status, header, body = call! env.merge("PATH_INFO" => "/charge", 
              "REQUEST_METHOD" => 'GET') 
          else
            content_type :json
            booking.to_json
          end

        end
     end

    end # BookingRESTApi
  end # YSD
end # Sinatra