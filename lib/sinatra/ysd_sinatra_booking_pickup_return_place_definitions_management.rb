module Sinatra
  module YitoExtension
    module BookingPickupReturnPlaceDefinitionsManagement

      def self.registered(app)

        #
        # Pickup/return places
        #
        app.get '/admin/booking/booking-place-defs/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          locals = {:booking_pickup_return_place_defs => 20}
          load_em_page :booking_pickup_return_place_defs_management, 
                       :booking_pickup_return_place_defs, false, :locals => locals

        end

        #
        # Pickup/return places edition
        #
        app.get '/admin/booking/booking-pickup-return-places/:id', :allowed_usergroups => ['booking_manager', 'staff'] do

          if @pickup_return_place_definition = ::Yito::Model::Booking::PickupReturnPlaceDefinition.get(params[:id])
            @show_translations = settings.multilanguage_site
            if @multiple_rental_locations = SystemConfiguration::Variable.get_value('booking.multiple_rental_locations', 'false').to_bool
              @rental_locations = ::Yito::Model::Booking::RentalLocation.all
            else
              @rental_locations = []
            end
            load_page :booking_pickup_return_place_definition_edition
          else
            status 404
          end

        end

      end

    end
  end
end