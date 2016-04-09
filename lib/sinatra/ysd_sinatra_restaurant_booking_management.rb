module Sinatra
  module YSD
    #
    # Sinatra extension to manage restaurant bookings
    #
    module RestaurantBookingManagement

      def self.registered(app)

        #
        # Create new booking (administation)
        #
        ['/admin/restaurant/booking/new/:booking_catalog_code', '/admin/restaurant/booking/new'].each do |path|
          app.get path, :allowed_usergroups => ['booking_manager', 'staff'] do

            locals = {}
            locals.store(:admin_mode, true)
            locals.store(:afternoon_turns,
              SystemConfiguration::Variable.get_value('booking.afternoon_turns').split(','))
            locals.store(:night_turns,
              SystemConfiguration::Variable.get_value('booking.night_turns').split(','))
            locals.store(:max_people,
          	  SystemConfiguration::Variable.get_value('booking.max_adults'))
            locals.store(:max_people_extra,
          	  SystemConfiguration::Variable.get_value('booking.max_adults_extra'))
            locals.store(:confirm_booking_url,
              '/api/restaurant/booking')
            #booking_js = catalog_template
            #locals.store(:booking_js, booking_js.text) 
            locals.store(:booking_js, '')
            
            load_page('reserva-online-restaurant'.to_sym, :locals => locals)

          end
        end

      end

    end
  end
end