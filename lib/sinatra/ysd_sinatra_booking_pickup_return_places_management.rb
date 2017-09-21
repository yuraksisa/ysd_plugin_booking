module Sinatra
  module YitoExtension
    module BookingPickupReturnPlacesManagement

      def self.registered(app)

        #
        # Pickup/return places
        #
        app.get '/admin/booking/booking-places/:place_def_id?*', :allowed_usergroups => ['booking_manager','staff'] do 
          
          if pickup_return_place_def = ::Yito::Model::Booking::PickupReturnPlaceDefinition.get(params[:place_def_id])
            locals = {:booking_pickup_return_places => 20,
                      :pickup_return_place_definition => pickup_return_place_def,
                      :multiple_rental_locations => SystemConfiguration::Variable.get_value('booking.multiple_rental_locations', 'false').to_bool}

            load_em_page :booking_pickup_return_places_management, 
                       :booking_pickup_return_places, false, :locals => locals
          else
            status 404
          end

        end

      end

    end
  end
end