module Sinatra
  module YSD
    #
    # Sinatra extension to manage restaurant bookings
    #
    module RestaurantBookingManagementRESTApi

      def self.registered(app)

      	app.post '/api/restaurant/booking/?*' do
      		
          request.body.rewind 
          data = JSON.parse request.body.read
          data.symbolize_keys!  

          date_from = data[:date_from]
          time_from = data[:time_from]
          number_of_adults = data[:number_of_adults]
          customer_name = data[:customer_name]
          customer_surname = data[:customer_surname]
          customer_phone = data[:customer_phone]
          customer_email = data[:customer_email]
          comments = data[:comments]
          
          # Calculate the finishing time
          duration_of_service = SystemConfiguration::Variable.get_value('booking.duration_of_service')
          duration_of_service_extra = SystemConfiguration::Variable.get_value('booking.duration_of_service_extra')
          extra_turns = SystemConfiguration::Variable.get_value('booking.duration_of_service_extra_turns').split(',')
          last_time = SystemConfiguration::Variable.get_value('booking.scheduler_finish_time')
          duration = if extra_turns.include?time_from
                       Time.parse(duration_of_service_extra)
                     else
                       Time.parse(duration_of_service)
                     end
          start_time = Time.parse(time_from)
          end_time = start_time + duration.hour * 3600 + duration.min * 60
          time_to = if end_time.day > start_time.day
                      last_time
                    else
                      end_time.strftime("%H:%M")
                    end

          # Booking
          booking = BookingDataSystem::Booking.new
          booking.date_from = date_from 
          booking.time_from = time_from
          booking.date_to = date_from
          booking.time_to = time_to 
          booking.number_of_adults = number_of_adults 
          booking.customer_name = customer_name 
          booking.customer_surname = customer_surname 
          booking.customer_phone = customer_phone 
          booking.customer_email = customer_email 
          booking.comments = comments
          booking.item_cost = 0
          booking.extras_cost = 0
          booking.time_from_cost = 0
          booking.time_to_cost = 0
          booking.product_deposit_cost = 0
          booking.total_cost = 0
          booking.total_paid = 0
          booking.total_pending = 0
          booking.booking_amount = 0

          # Booking lines (one for each table type)
          tables_layout = JSON.parse(SystemConfiguration::Variable.get_value('booking.people_resources'))
          tables = tables_layout[number_of_adults]
          tables.each do |key, value| 
            booking_category = ::Yito::Model::Booking::BookingCategory.get(key)
            booking_line = BookingDataSystem::BookingLine.new
            booking_line.item_id = key
            booking_line.item_description = booking_category.description
            booking_line.item_unit_cost = 0
            booking_line.item_cost = 0
            booking_line.quantity = value
            booking_line.booking = booking 
            (1..value).each do |item|
              booking_line_resource = BookingDataSystem::BookingLineResource.new
              booking_line_resource.booking_line = booking_line
              booking_line.booking_line_resources << booking_line_resource
            end
            booking.booking_lines << booking_line 
          end

          booking.init_user_agent_data(request.env["HTTP_USER_AGENT"])
          booking.save

          session[:booking_id] = booking.id

          response =  <<-HTML
                         <script type="text/javascript">
                         window.location.href= "/p/restaurant/booking/summary"
                         </script>
                       HTML
          status 200
          body response

      	end

      end

    end
  end
end