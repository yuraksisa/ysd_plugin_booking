module Sinatra
  module YSD
    #
    # Sinatra extension to manage restaurant bookings
    #
    module RestaurantBooking

   
      def self.registered(app) 

      	#
      	# Restaurant booking reservation start 
      	#
        app.get '/p/restaurant/booking/start/?*' do 
  
          options = {}
          options.store(:page_title,
              SystemConfiguration::Variable.get_value('booking.page_title'))
          options.store(:page_description,
              SystemConfiguration::Variable.get_value('booking.page_description'))
          options.store(:page_language, session[:locale])
          options.store(:page_keywords,
              SystemConfiguration::Variable.get_value('booking.page_keywords'))          
          options.store(:layout, params['layout']=='false'? false : params['layout']) if params.has_key?('layout')

          locals = {}
          locals.store(:afternoon_turns,
            SystemConfiguration::Variable.get_value('booking.afternoon_turns').split(','))
          locals.store(:night_turns,
            SystemConfiguration::Variable.get_value('booking.night_turns').split(','))
          locals.store(:max_people,
          	SystemConfiguration::Variable.get_value('booking.max_adults'))
          locals.store(:max_people_extra,
          	SystemConfiguration::Variable.get_value('booking.max_adults_extra'))
          booking_js = catalog_template
          locals.store(:booking_js, booking_js.text) 


          load_page('reserva-online-restaurant'.to_sym, options.merge(:locals => locals))

        end

      end

    end
  end
end