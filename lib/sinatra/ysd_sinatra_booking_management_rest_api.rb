require 'ysd_md_configuration' unless defined?SystemConfiguration::Variable
require 'ysd_md_booking' unless defined?BookingDataSystem::Booking
require 'date'
module Sinatra
  module YSD

  	module BookingManagementRESTApi
      
      def self.registered(app)

        #
        # Check resources available for a period
        #
        app.get '/api/booking/available-resources', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff']  do

          if params[:from]
            begin
              @date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("date not valid #{params[:from]}")
            end

            if params[:to]
              begin
                @date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
              rescue
                logger.error("date not valid #{params[:to]}")
              end
              data, detail = BookingDataSystem::Booking.resources_occupation(@date_from, @date_to)
              status 200
              detail.to_json
            else
              status 500
            end 
          else
            status 500
          end

        end

        #
        # Booking statistics
        #
        app.get '/api/booking/statistics', :allowed_usergroups => ['booking_manager', 'staff']  do

          year = params[:year] || Date.today.year

          received = BookingDataSystem::Booking.reservations_received(year)
          confirmed = BookingDataSystem::Booking.reservations_confirmed(year)
          
          result = {}

          (1..12).each do |element| 
            period = "#{year}-#{element.to_s.rjust(2, '0')}"
            result.store(period, {requests: 0, confirmed: 0})
          end          

          received.each do |item|
            result.store(item.period, :requests => item.occurrences, :confirmed => 0)
          end
          
          confirmed.each do |item|
            result.fetch(item.period).store(:confirmed, item.occurrences)
          end

          result.to_json

        end

        #
        # Incoming money
        #
        app.get '/api/booking/incoming-money', :allowed_usergroups => ['booking_manager', 'staff']  do

          year = params[:year] || Date.today.year

          data = BookingDataSystem::Booking.incoming_money_summary(year)

          result = {}

          (1..12).each do |element| 
            period = "#{year}-#{element.to_s.rjust(2, '0')}"
            result.store(period, {total: 0})
          end  

          data.each do |item|
            result.store(item.period, :total => sprintf("%.2f", item.total))
          end

          result.to_json

        end 

        #
        # Bookings scheduler
        #
        app.get '/api/booking/scheduler/:booking_item_reference', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          from = Time.at(params['start'].to_i)
          to = Time.at(params['end'].to_i)

          condition = Conditions::JoinComparison.new('$and',
           [Conditions::Comparison.new('booking_line.booking.status', '$ne', :cancelled),
            Conditions::Comparison.new(:booking_item_reference, '$eq', params[:booking_item_reference]),
            Conditions::JoinComparison.new('$or', 
              [Conditions::JoinComparison.new('$and', 
                 [Conditions::Comparison.new('booking_line.booking.date_from','$lte', from),
                  Conditions::Comparison.new('booking_line.booking.date_to','$gte', from)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from','$lte', to),
                  Conditions::Comparison.new('booking_line.booking.date_to','$gte', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from','$eq', from),
                  Conditions::Comparison.new('booking_line.booking.date_to','$eq', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from', '$gte', from),
                  Conditions::Comparison.new('booking_line.booking.date_to', '$lte', to)])               
              ]
            ),
            ]
          )

          bookings = condition.build_datamapper(BookingDataSystem::BookingLineResource).all(
             ).map do |booking_line_resource|
            booking = booking_line_resource.booking_line.booking
            {:id => booking.id,
             :title => "#ID: #{booking.id} \n #{booking.date_from.strftime('%Y-%m-%d')} #{booking.time_from} \n #{booking.date_to.strftime('%Y-%m-%d')} #{booking.time_to} \n #{booking.customer_name.upcase} #{booking.customer_surname.upcase} #{(booking.customer_phone.nil? or booking.customer_phone.empty?)? booking.customer_mobile_phone : booking.customer_phone}",
             :start => booking.date_from,
             :end => booking.date_to,
             :url => "/admin/booking/bookings/#{booking.id}",
             :editable => false,
             :backgroundColor => (booking.status==:confirmed)? 'rgb(41, 158, 69)' : (booking.status==:in_progress)? 'rgb(13, 124, 226)' : (booking.status == :pending_confirmation)? 'rgb(241, 248, 69)' : 'rgb(0,0,0)',
             :textColor => (booking.status == :pending_confirmation)? 'black' : 'white'}
          end

          bookings.to_json

        end

        #
        # Bookings scheduler
        #
        app.get '/api/booking/scheduler', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          from = Time.at(params['start'].to_i)
          to = Time.at(params['end'].to_i)

          condition = Conditions::JoinComparison.new('$and',
           [Conditions::Comparison.new('booking_line.booking.status', '$ne', :cancelled),
            Conditions::JoinComparison.new('$or', 
              [Conditions::JoinComparison.new('$and', 
                 [Conditions::Comparison.new('booking_line.booking.date_from','$lte', from),
                  Conditions::Comparison.new('booking_line.booking.date_to','$gte', from)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from','$lte', to),
                  Conditions::Comparison.new('booking_line.booking.date_to','$gte', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from','$eq', from),
                  Conditions::Comparison.new('booking_line.booking.date_to','$eq', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from', '$gte', from),
                  Conditions::Comparison.new('booking_line.booking.date_to', '$lte', to)])               
              ]
            ),
            ]
          )

          bookings = condition.build_datamapper(BookingDataSystem::BookingLineResource).all(
             ).map do |booking_line_resource|
            booking = booking_line_resource.booking_line.booking
            start_str = "#{booking.date_from.strftime('%Y-%m-%d')}T#{booking.time_from}:00"
            end_str = "#{booking.date_to.strftime('%Y-%m-%d')}T#{booking.time_to}:00"
            {:id => booking.id,
             :title => "#ID: #{booking.id} \n #{booking.customer_name.upcase} #{booking.customer_surname.upcase} (#{booking.number_of_adults}) \n #{(booking.customer_phone.nil? or booking.customer_phone.empty?)? booking.customer_mobile_phone : booking.customer_phone}",
             :start => start_str,
             :end => end_str,
             :allDay => false,
             :url => "/admin/simple/booking/bookings/#{booking.id}",
             :editable => false,
             :backgroundColor => (booking.status==:confirmed)? 'rgb(41, 158, 69)' : (booking.status==:in_progress)? 'rgb(13, 124, 226)' : (booking.status == :pending_confirmation)? 'rgb(241, 248, 69)' : 'rgb(0,0,0)',
             :textColor => (booking.status == :pending_confirmation)? 'black' : 'white'}
          end

          bookings.to_json

        end


        #
        # Get the confirmed bookings that have not been assigned
        #
        # Params
        #
        # @param [month]
        # @param [year]
        #
        app.get '/api/booking/confirmed', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do
          
          condition = booking_confirmed_conditions(params)

          bookings = condition.build_datamapper(BookingDataSystem::Booking).all(
             :order => [:date_from.asc]
            )

          bookings.to_json(:only => [:id, :date_from, :time_from, :date_to, :time_to, :customer_name, :customer_surname,
              :customer_phone, :customer_mobile_phone, :status, :planning_color], 
                           :relationships => {:booking_line_resources => {}})

        end

        #
        # Get the items that have to be pick up
        #
        app.get '/api/booking/pickedup', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

           from = DateTime.now
           if params[:from]
             from = DateTime.strptime(params[:from], '%Y-%m-%d')
           end

           to = from
           if params[:to]
             to = DateTime.strptime(params[:to], '%Y-%m-%d')
           end

           # Rental Location
           rental_location_code = nil
           multiple_locations = SystemConfiguration::Variable.get_value('booking.multiple_rental_locations', 'false').to_bool
           allow_booking_operator_multiple_locations = SystemConfiguration::Variable.get_value('booking.multiple_rental_locations_allow_operator_all_locations', 'false').to_bool

           if multiple_locations
             if params[:rental_location]
               rental_location_code = params[:rental_location]
             else
               if rental_location_user = ::Yito::Model::Booking::RentalLocationUser.first('user.username'.to_sym => user.username)
                 if rental_location_user.user.belongs_to?('booking_operator')
                   rental_location_code = rental_location_user.rental_location.code unless allow_booking_operator_multiple_locations
                 end
               end
             end
           end

           # Journal addon
           addons = mybooking_addons
           addon_journal = (addons and addons.has_key?(:addon_journal) and addons[:addon_journal])

           # Query
           data = BookingDataSystem::Booking.pickup_list(from, to , rental_location_code,addon_journal)

           data.to_json

        end

        #
        # Get the items that have to be returned
        #
        app.get '/api/booking/returned', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

           from = DateTime.now
           if params[:from]
             from = DateTime.strptime(params[:from], '%Y-%m-%d')
           end

           to = from
           if params[:to]
             to = DateTime.strptime(params[:to], '%Y-%m-%d')
           end

           # Rental location
           rental_location_code = nil
           multiple_locations = SystemConfiguration::Variable.get_value('booking.multiple_rental_locations', 'false').to_bool
           if multiple_locations
             if params[:rental_location]
               rental_location_code = params[:rental_location]
             else
               if rental_location_user = ::Yito::Model::Booking::RentalLocationUser.first('user.username'.to_sym => user.username)
                 rental_location_code = rental_location_user.rental_location.code if rental_location_user.user.belongs_to?('booking_operator')
               end
             end
           end

           # Journal addon
           addons = mybooking_addons
           addon_journal = (addons and addons.has_key?(:addon_journal) and addons[:addon_journal])

           data = BookingDataSystem::Booking.return_list(from, to, rental_location_code, addon_journal)

           data.to_json
          
        end
        
        # ------------------------ BOOKING MANAGER ---------------------------------------

        #
        # Booking querying
        #
        ["/api/bookings", "/api/bookings/page/:page"].each do |path|
          app.post path, :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

            page = [params[:page].to_i, 1].max
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:id.desc]}

            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))

              if search_request.has_key?('status') and ['pending','in_process','confirmed','received'].include?(search_request['status'])
                today = Date.today.to_date
                first_year_date = Date.civil(today.year, 1, 1)
                if search_request['status'] == 'pending'
                  data, total = BookingDataSystem::Booking.all_and_count(
                      {:conditions => {:status => [:pending_confirmation],
                                       :date_from.gte => today}}.merge(offset_order_query))
                elsif search_request['status'] == 'in_process'
                  data, total = BookingDataSystem::Booking.all_and_count(
                      {:conditions => {:status => [:confirmed, :in_progress],
                                      :date_from.lte => today,
                                      :date_to.gte => today}}.merge(offset_order_query))
                elsif search_request['status'] == 'confirmed'
                  data, total = BookingDataSystem::Booking.all_and_count(
                      {:conditions => {:status => [:confirmed, :in_progress, :done],
                                      :creation_date.gte => first_year_date}}.merge(offset_order_query))
                elsif search_request['status'] == 'received'
                  data, total = BookingDataSystem::Booking.all_and_count(
                      {:conditions => {:creation_date.gte => first_year_date}}.merge(offset_order_query))
                end
              elsif search_request.has_key?('search') and (search_request['search'].to_s.strip.length > 0)
                total, data = BookingDataSystem::Booking.text_search(search_request['search'],offset_order_query)
              else
                data, total = BookingDataSystem::Booking.all_and_count(offset_order_query)
              end

            else
                data, total = BookingDataSystem::Booking.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json

          end
        end

        #
        # Booking management : Search for a main booking to assign
        #
        app.get '/api/bookings/main-search/:id/?*', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do
          search_text = params[:term]
          
          conditions =  Conditions::JoinComparison.new('$and',
                        [ Conditions::Comparison.new(:id, '$ne', params[:id]),
                          Conditions::Comparison.new(:main_booking_id, '$eq', nil),
                          Conditions::JoinComparison.new('$or', 
                             [Conditions::Comparison.new(:id, '$eq', search_text.to_i),
                              Conditions::Comparison.new(:customer_name, '$like', "%#{search_text}%"),
                              Conditions::Comparison.new(:customer_surname, '$like', "%#{search_text}%"),
                              Conditions::Comparison.new(:customer_email, '$eq', search_text)
                             ])
                        ])

          data = conditions.build_datamapper(BookingDataSystem::Booking).all.map do |booking|
            {:value => booking.id,
             :label => "#{booking.id} - #{booking.date_from.strftime('%Y-%m-%d')} - #{booking.date_to.strftime('%Y-%m-%d')} - #{booking.customer_name.upcase} #{booking.customer_surname.upcase} "
            } 
          end
          data.to_json

        end
        
        #
        # Get the reservations that linked to this one
        #
        app.get '/api/bookings/linked/:id/?*', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          result = if booking = BookingDataSystem::Booking.get(params[:id])
                     conditions = if booking.main_booking 
                                    Conditions::JoinComparison.new('$or', [
                                      Conditions::Comparison.new(:main_booking_id, '$eq', booking.main_booking.id),
                                      Conditions::Comparison.new(:id, '$eq', booking.main_booking.id)])
                                  else
                                    Conditions::JoinComparison.new('$or', [
                                      Conditions::Comparison.new(:main_booking_id, '$eq', booking.id),
                                      Conditions::Comparison.new(:id, '$eq', booking.id)
                                      ])
                                  end   
                     conditions.build_datamapper(BookingDataSystem::Booking).all.map do |booking|
                        {:id => booking.id,
                         :customer_name => booking.customer_name,
                         :customer_surname => booking.customer_surname,
                         :date_from => booking.date_from,
                         :time_from => booking.time_from,
                         :date_to => booking.date_to,
                         :time_to => booking.time_to,
                         :main_booking_id => booking.main_booking_id,
                         :status => booking.status,
                         :detail => booking.booking_lines.inject("") { |result, item| result + "#{item.quantity}-#{item.item_id} " }.strip
                         }
                     end
                   else
                     []
                   end

          result.to_json

        end

        #
        # Unlink a booking
        # 
        app.post '/api/booking/unlink/:booking_id', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if booking = BookingDataSystem::Booking.get(params[:booking_id])
            booking.main_booking = nil
            booking.save
            content_type :json
            status 200
            booking.to_json
          else
            status 404
          end

        end

        # -------------------- Allow/Deny payment ----------------------------

        #
        # Allow payment
        #
        app.post '/api/booking/allow-payment/:booking_id', 
          :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            booking.force_allow_payment = true
            booking.save
            booking.notify_customer_payment_enabled
            content_type :json
            booking.to_json
          else
            status 404
          end

        end

        #
        # Deny payment
        #
        app.post '/api/booking/not-allow-payment/:booking_id', 
          :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            booking.force_allow_payment = false
            booking.save
            content_type :json
            booking.to_json
          else
            status 404
          end

        end        

        #
        # Assign a booking item to a booking line resource
        #
        app.post '/api/booking/assign/:id/:booking_item_reference',
          :allowed_usergroups => ['booking_manager', 'booking_operator','staff'] do

          if booking_line_resource = BookingDataSystem::BookingLineResource.get(params[:id].to_i)
            if booking_item = ::Yito::Model::Booking::BookingItem.get(params[:booking_item_reference])
              booking_line_resource.booking_item_category = booking_item.category.code if booking_item.category
              booking_line_resource.booking_item_reference = booking_item.reference
              booking_line_resource.booking_item_stock_model = booking_item.stock_model
              booking_line_resource.booking_item_stock_plate = booking_item.stock_plate
              booking_line_resource.booking_item_characteristic_1 = booking_item.characteristic_1
              booking_line_resource.booking_item_characteristic_2 = booking_item.characteristic_2
              booking_line_resource.booking_item_characteristic_3 = booking_item.characteristic_3
              booking_line_resource.booking_item_characteristic_4 = booking_item.characteristic_4              
              booking_line_resource.save
              content_type :json
              booking_line_resource.to_json
            else
              p "Booking Line Resource not found"
              status 404
            end  
          else
            p "Booking item not found"
            status 404
          end 

        end

        # ------------- Lifecycle management : confirm, pickup/arrival, return/departure, cancel --------------------

        #
        # Confirm a booking
        #
        app.post '/api/booking/confirm/:booking_id',
                 :allowed_usergroups => ['booking_manager', 'booking_operator','staff'] do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            content_type :json
            result = booking.confirm!
            booking.notify_customer if booking.total_paid > 0
            result.to_json
          else
            status 404
          end

        end

        #
        # Pickup/Arrival 
        #
        app.post '/api/booking/pickup/:booking_id',
          :allowed_usergroups => ['booking_manager', 'booking_operator','staff']  do
       
          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            content_type :json
            booking.pickup_item.to_json
          else
            status 404
          end
    
        end

        #
        # Return/Departure
        #
        app.post '/api/booking/return/:booking_id',
          :allowed_usergroups => ['booking_manager', 'booking_operator','staff']  do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            content_type :json
            booking.return_item.to_json
          else
            status 404
          end

        end

        #
        # Cancel a reservation
        #
        app.post '/api/booking/cancel/:booking_id',
          :allowed_usergroups => ['booking_manager', 'booking_operator','staff']  do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            content_type :json
            booking.cancel.to_json
          else
            status 404
          end

        end

        # ---------------------- Change pickup/return date/place -----------------------------------------------------

        #
        # Edit booking pickup-return place and/or date time
        #
        # Get detailed prices for a date_from (time_from), date_to (time_to), pickup and return places
        #
        app.post '/api/booking/prices', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys!

          # Retrieve date/time from - to
          date_from = DateTime.strptime(data[:date_from],'%Y-%m-%d')
          time_from = data[:time_from]
          date_to =  DateTime.strptime(data[:date_to],'%Y-%m-%d')
          time_to = data[:time_to]
          # Calculate days
          days_calculus = BookingDataSystem::Booking.calculate_days(date_from, time_from, date_to, time_to)
          days = days_calculus[:days]
          date_to_price_calculation = days_calculus[:date_to_price_calculation]

          # Retrieve pickup/return place
          pickup_place, custom_pickup_place, pickup_place_customer_translation,
          return_place, custom_return_place, return_place_customer_translation = request_pickup_return_place(data)
          # Retrieve number of adutls and children
          number_of_adults = data[:number_of_adults]
          number_of_children = data[:number_of_children]
          # Retrieve driver age rule
          driver_rule_definition_id = SystemConfiguration::Variable.get_value('booking.driver_min_age.rule_definition')
          driver_rule_definition = driver_rule_definition_id ? ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(driver_rule_definition_id) : nil
          # Retrieve sales channel
          sales_channel_code = data[:sales_channel_code]
          sales_channel_code = nil if sales_channel_code and sales_channel_code.empty?
          # Retrieve promotion code
          promotion_code = data[:promotion_code]
          promotion_code = nil if promotion_code and promotion_code.empty?

          date_of_birth = DateTime.strptime(data[:date_of_birth],'%Y-%m-%d') if data.has_key?(:date_of_birth) && !data[:date_of_birth].nil? && !data[:date_of_birth].empty?
          driver_driving_license_date = DateTime.strptime(data[:driver_driving_license_date],'%Y-%m-%d') if data.has_key?(:driver_driving_license_date) && !data[:driver_driving_license_date].nil? && !data[:driver_driving_license_date].empty?

          # Prepare the supplements
          calculator = ::Yito::Model::Booking::RentingCalculator.new(date_from, time_from, date_to, time_to, days, date_to_price_calculation, 
                                                                     pickup_place, return_place,
                                                                     {driver_age_mode: :dates,
                                                                      driver_date_of_birth: date_of_birth,
                                                                      driver_driving_license_date: driver_driving_license_date,
                                                                      driver_age_rule_definition: driver_rule_definition},
                                                                     custom_pickup_place, custom_return_place)

          locale = session[:locale]#locale_to_translate_into
          
          # Prepare the products
          products = ::Yito::Model::Booking::BookingCategory.search(date_from,
                                                                    date_to,
                                                                    calculator.days,
                                                                    {
                                                                      locale: locale,
                                                                      full_information: true,
                                                                      product_code: nil,
                                                                      web_public: false,
                                                                      sales_channel_code: sales_channel_code,
                                                                      apply_promotion_code: !promotion_code.nil?,
                                                                      promotion_code: promotion_code})

          # Prepare the extras
          extras = ::Yito::Model::Booking::RentingExtraSearch.search(date_from,
                                                                     date_to, calculator.days, locale)

          content_type :json
          {calculator: calculator, products: products, extras: extras}.to_json

        end

        #
        # Update the booking price
        #
        app.put '/api/booking/:id/price', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request = body_as_json
          booking_request = body_as_json(BookingDataSystem::Booking)
          lines_request = booking_request.delete(:booking_lines)
          extras_request = booking_request.delete(:booking_extras)
 
          booking = BookingDataSystem::Booking.get(params[:id])
          booking.transaction do
            old_booking_pickup_place_cost = booking.pickup_place_cost
            old_booking_return_place_cost = booking.return_place_cost
            old_booking_time_from_cost = booking.time_from_cost
            old_booking_time_to_cost = booking.time_to_cost
            old_booking_total_cost = booking.total_cost

            pickup_place, custom_pickup_place, pickup_place_customer_translation,
            return_place, custom_return_place, return_place_customer_translation = request_pickup_return_place(request)

            booking.attributes = booking_request
            booking.pickup_place = pickup_place
            booking.custom_pickup_place = custom_pickup_place
            booking.pickup_place_customer_translation = pickup_place_customer_translation
            booking.return_place = return_place
            booking.custom_return_place = custom_return_place
            booking.return_place_customer_translation = return_place_customer_translation

            # Calculate driver age and driving license years
            booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
            if booking_item_family.driver_date_of_birth
              booking.driver_age = BookingDataSystem::Booking.completed_years(booking.date_from,
                                                                              booking.driver_date_of_birth) unless booking.driver_date_of_birth.nil?
              booking.driver_driving_license_years = BookingDataSystem::Booking.completed_years(booking.date_from,
                                                                                                booking.driver_driving_license_date) unless booking.driver_driving_license_date.nil?
            end

            booking.calculate_cost(false, false)
            booking.save
            lines_request.each do |line_booking| 
              booking_line = BookingDataSystem::BookingLine.get(line_booking[:id])
              booking_line.item_cost = line_booking[:item_cost]
              booking_line.item_unit_cost = line_booking[:item_unit_cost]
              booking_line.save
            end
            extras_request.each do |extra_booking|
              booking_extra = BookingDataSystem::BookingExtra.get(extra_booking[:id])
              booking_extra.extra_cost = extra_booking[:extra_cost]
              booking_extra.extra_unit_cost = extra_booking[:extra_unit_cost]
              booking_extra.save
            end

            product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))

            # News feed
            pickup_booking = booking.date_from.strftime('%Y-%m-%d')
            pickup_booking << ' '
            pickup_booking << booking.time_from if product_family.time_to_from
            pickup_booking << ' '
            #pickup_booking << booking.pickup_place if product_family.pickup_return_place
            return_booking = booking.date_to.strftime('%Y-%m-%d')
            return_booking << ' '
            #return_booking << booking.time_to if product_family.time_to_from
            return_booking << ' '
            return_booking << booking.return_place if product_family.pickup_return_place
            ::Yito::Model::Newsfeed::Newsfeed.create(category: 'booking',
                                                     action: 'change_dates',
                                                     identifier: booking.id.to_s,
                                                     description: BookingDataSystem.r18n.t.booking_news_feed.change_dates(pickup_booking,
                                                                      return_booking, "%.2f" % booking.total_cost, "%.2f" % old_booking_total_cost),
                                                     attributes_updated: booking_request.merge({booking: booking.newsfeed_summary}).to_json)
          end

        end

        # ---------------------------- CRUD ----------------------------------

        #
        # Get a booking
        #
        app.get '/api/booking/:booking_id',
                :allowed_usergroups => ['booking_manager', 'booking_operator','staff'] do

          if booking=BookingDataSystem::Booking.get(params[:booking_id])
            status 200
            booking.to_json
          else
            status 404
          end

        end

        #
        # Updates booking
        #
        app.put '/api/booking/:id', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff']  do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys! 

          if booking = BookingDataSystem::Booking.get(params[:id])
            booking.attributes = data
            booking.save
            body booking.to_json
          else
            status 404
          end
          

        end

        #
        # Update booking
        #
        app.put '/api/booking', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          data_request = body_as_json(BookingDataSystem::Booking)

          if booking = BookingDataSystem::Booking.get(data_request.delete(:id).to_i)
            data_request.each do |k,v|
              if [:driver_date_of_birth,
                  :driver_driving_license_date,
                  :driver_driving_license_expiration_date,
                  :driver_document_id_date,
                  :driver_document_id_expiration_date,
                  :additional_driver_1_date_of_birth,
                  :additional_driver_1_driving_license_date,
                  :additional_driver_1_driving_license_expiration_date,
                  :additional_driver_1_document_id_date,
                  :additional_driver_1_document_id_expiration_date,
                  :additional_driver_2_date_of_birth,
                  :additional_driver_2_driving_license_date,
                  :additional_driver_2_driving_license_expiration_date,
                  :additional_driver_2_document_id_date,
                  :additional_driver_2_document_id_expiration_date,
                  :additional_driver_3_date_of_birth,
                  :additional_driver_3_driving_license_date,
                  :additional_driver_3_driving_license_expiration_date,
                  :additional_driver_3_document_id_date,
                  :additional_driver_3_document_id_expiration_date,
                  :external_invoice_date].include?(k)
                data_request[k] = nil if v.empty?
              end
            end

            # Driver address update
            if data_request.has_key?(:driver_address)
              driver_address = data_request.delete(:driver_address)
              if booking.driver_address.nil?
                booking.driver_address = driver_address
              else
                booking.driver_address.attributes = driver_address
              end
            end

            # Destination address update
            if data_request.has_key?(:destination_address)
              destination_address = data_request.delete(:destination_address)
              if booking.destination_address.nil?
                booking.destination_address = destination_address
              else
                booking.destination_address.attributes = destination_address
              end
            end

            booking.attributes=data_request

            # Calculate driver age and driving license years
            updated_driver_age_driving_license_years = false
            booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
            if booking_item_family and booking_item_family.driver_date_of_birth
              if data_request.has_key?(:driver_date_of_birth) and !data_request[:driver_date_of_birth].nil?
                booking.driver_age = BookingDataSystem::Booking.completed_years(booking.date_from,
                                                                                booking.driver_date_of_birth)
                updated_driver_age_driving_license_years = true
              end
            end
            if booking_item_family and booking_item_family.driver_license
              if data_request.has_key?(:driver_driving_license_date) and !data_request[:driver_driving_license_date].nil?
                booking.driver_driving_license_years = BookingDataSystem::Booking.completed_years(booking.date_from,
                                                                                                  booking.driver_driving_license_date)
                updated_driver_age_driving_license_years = true
              end
            end

            # Driver date of birth or driver driving license date update
            if SystemConfiguration::Variable.get_value('booking.driver_min_age.rules', 'false').to_bool and
               !SystemConfiguration::Variable.get_value('booking.driver_min_age.rule_definition','').empty?
              booking.calculate_cost(true, true) if updated_driver_age_driving_license_years # Calculates the cost applying the driver
            end

            # Prepare updated attributes
            updated_attributes = {}
            booking.dirty_attributes.each do |key, value|
              updated_attributes.store(key.name, value) unless value.nil?
            end

            if booking.driver_address
              booking.driver_address.dirty_attributes.each do |key, value|
                updated_attributes.store("driver_address.#{key.name}", value) unless value.nil?
              end
            end

            if booking.destination_address
              booking.destination_address.dirty_attributes.each do |key, value|
                updated_attributes.store("destination_address.#{key.name}", value) unless value.nil?
              end
            end

            booking.save
            # Newsfeed
            ::Yito::Model::Newsfeed::Newsfeed.create(category: 'booking',
                                                     action: 'updated_booking',
                                                     identifier: booking.id.to_s,
                                                     description: BookingDataSystem.r18n.t.booking_news_feed.updated_booking,
                                                     attributes_updated: updated_attributes.to_json)
          end

          content_type :json
          booking.to_json

        end

        #
        # Update booking supplements
        #
        app.post '/api/booking/booking-supplements', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do
          
          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!
          
          id = data_request[:booking_id]
          time_from_cost = data_request[:time_from_cost]
          time_to_cost = data_request[:time_to_cost]
          pickup_place_cost = data_request[:pickup_place_cost]
          return_place_cost = data_request[:return_place_cost]
          driver_age_cost = data_request[:driver_age_cost] || 0

          product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))

          if booking = BookingDataSystem::Booking.get(id)
            if data_request[:time_from_cost] or data_request[:time_to_cost] or
               data_request[:pickup_place_cost] or data_request[:return_place_cost] 
              # Prepare information for newsfeed
              updated_attributes = {}
              supplements_detail = []
              if booking.time_from_cost != time_from_cost
                updated_attributes.store(:time_from_cost, time_from_cost)
                supplements_detail << BookingDataSystem.r18n.t.booking_news_feed.updated_time_from_cost("%.2f" % time_from_cost, "%.2f" % booking.time_from_cost)
              end
              if booking.time_to_cost != time_to_cost
                updated_attributes.store(:time_to_cost, time_to_cost)
                supplements_detail << BookingDataSystem.r18n.t.booking_news_feed.updated_time_to_cost("%.2f" % time_to_cost, "%.2f" % booking.time_to_cost)
              end
              if booking.pickup_place_cost != pickup_place_cost
                updated_attributes.store(:pickup_place_cost, pickup_place_cost)
                supplements_detail << BookingDataSystem.r18n.t.booking_news_feed.updated_pickup_place_cost("%.2f" % pickup_place_cost, "%.2f" % booking.pickup_place_cost)
              end
              if booking.return_place_cost != return_place_cost
                updated_attributes.store(:return_place_cost, return_place_cost)
                supplements_detail << BookingDataSystem.r18n.t.booking_news_feed.updated_return_place_cost("%.2f" % return_place_cost, "%.2f" % booking.return_place_cost)
              end
              if booking.driver_age_cost != driver_age_cost
                updated_attributes.store(:driver_age_cost, driver_age_cost)
                supplements_detail << BookingDataSystem.r18n.t.booking_news_feed.updated_driver_age_cost("%.2f" % driver_age_cost, "%.2f" % booking.driver_age_cost)
              end
              # Update booking
              booking.time_from_cost = time_from_cost
              booking.time_to_cost = time_to_cost 
              booking.pickup_place_cost = pickup_place_cost 
              booking.return_place_cost = return_place_cost
              booking.driver_age_cost = driver_age_cost if product_family and product_family.driver
              booking.calculate_cost(false, false)
              booking.save
              # Newsfeed
              unless updated_attributes.empty?
                ::Yito::Model::Newsfeed::Newsfeed.create(category: 'booking',
                                                         action: 'updated_supplements',
                                                         identifier: booking.id.to_s,
                                                         description: BookingDataSystem.r18n.t.booking_news_feed.updated_supplements(supplements_detail.join('. ')),
                                                         attributes_updated: updated_attributes.to_json)
              end
              booking.reload
              content_type :json
              booking.to_json
            else
              body "Ningún suplemento especificado"
            end
          else
            status 404
          end

        end

        #
        # Create booking line
        #
        app.post '/api/booking/booking-line', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_id]

          if booking = BookingDataSystem::Booking.get(id)
            if data_request[:item_id] and data_request[:quantity]
              item_id = data_request[:item_id]
              quantity = data_request[:quantity].to_i
              booking.add_booking_line(item_id, quantity)
              booking.reload
              content_type :json
              booking.to_json
            else 
              body "Producto o cantidad no especificadas"
              status 500
            end
          else
            status 404
          end
        end
        
        #
        # Create booking extra
        #
        app.post '/api/booking/booking-extra', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_id]

          if booking = BookingDataSystem::Booking.get(id)
            if data_request[:extra_id] and data_request[:quantity]
              extra_id = data_request[:extra_id]
              quantity = data_request[:quantity].to_i
              booking.add_booking_extra(extra_id, quantity)
              booking.reload
              content_type :json
              booking.to_json
            else 
              body "Extra o cantidad no especificadas"
              status 500
            end
          else
            status 404
          end
        end

        #
        # Update booking line item
        #
        app.put '/api/booking/booking-line/item-id', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!          
          id = data_request[:booking_line_id]
          if booking_line = BookingDataSystem::BookingLine.get(id)
            price_modification = data_request[:price_modification] # hold or update
            if data_request[:item_id] && data_request[:item_id] != booking_line.item_id
              item_id = data_request[:item_id]
              booking_line.change_item(item_id, price_modification)
              booking = booking_line.booking
              booking.reload
              content_type :json
              booking.to_json
            else
              body "Producto no especificado"
              status 500
            end
          else
            status 404
          end
            
        end

        #
        # Update booking line: quantity
        #
        app.put '/api/booking/booking-line/quantity', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!
          id = data_request[:booking_line_id]
          if booking_line = BookingDataSystem::BookingLine.get(id)
            if data_request[:quantity]
              quantity = data_request[:quantity]
              booking_line.update_quantity(quantity)
              booking = booking_line.booking
              booking.reload
              content_type :json
              booking.to_json
            else 
              body "Cantidad no especificada"
              status 500
            end
          else
            status 404
          end

        end
        
        #
        # Update booking line : item cost
        #
        app.put '/api/booking/booking-line/item-cost', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_line_id]
          if booking_line = BookingDataSystem::BookingLine.get(id)
            if data_request[:item_unit_cost]
              item_unit_cost = data_request[:item_unit_cost]
              booking_line.update_item_cost(item_unit_cost)
              booking = booking_line.booking
              booking.reload
              content_type :json
              booking.to_json
            else 
              body "Coste no especificado"
              status 500
            end
          else
            status 404
          end

        end

        #
        # Update booking line: deposit
        #
        app.put '/api/booking/booking-line/deposit', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_line_id]
          if booking_line = BookingDataSystem::BookingLine.get(id)
            if data_request[:item_deposit]
              booking_deposit = SystemConfiguration::Variable.get_value('booking.deposit', 0).to_i
              item_deposit = data_request[:item_deposit]
              booking_line.update_item_deposit(item_deposit)
              booking = booking_line.booking
              booking.reload
              content_type :json
              booking.to_json
            else 
              body "Fianza no especificada"
              status 500
            end
          else
            status 404
          end

        end

        #
        # Update booking deposit(s)
        #
        app.post '/api/booking/booking-deposits', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_id]
          driver_age_deposit = data_request[:driver_age_deposit]

          if booking = BookingDataSystem::Booking.get(id)
            if data_request[:driver_age_deposit]
              booking.update_driver_age_deposit(driver_age_deposit)
              booking.reload
              content_type :json
              booking.to_json
            end
          else
            status 404
          end

        end

        #
        # Update booking extra: quantity
        #
        app.put '/api/booking/booking-extra/quantity', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_extra_id]
          if booking_extra = BookingDataSystem::BookingExtra.get(id)
            if data_request[:quantity]
              quantity = data_request[:quantity]
              booking_extra.update_quantity(quantity)
              booking = booking_extra.booking
              booking.reload
              content_type :json
              booking.to_json
            else 
              body "Cantidad no especificada"
              status 500
            end
          else
            status 404
          end

        end
        
        #
        # Update booking extra : extra cost
        #
        app.put '/api/booking/booking-extra/extra-cost', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_extra_id]
          if booking_extra = BookingDataSystem::BookingExtra.get(id)
            if data_request[:extra_unit_cost]
              extra_unit_cost = data_request[:extra_unit_cost]
              booking_extra.update_cost(extra_unit_cost)
              booking = booking_extra.booking
              booking.reload
              content_type :json
              booking.to_json
            else 
              body "Coste no especificado"
              status 500
            end
          else
            status 404
          end

        end

        #
        # Update booking resource
        #
        app.put '/api/booking-line-resource', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys! 

          if booking_line_resource = BookingDataSystem::BookingLineResource.get(data.delete(:id).to_i)
            booking_item_reference = data.delete(:booking_item_reference)
            # Assign booking item information
            if !booking_item_reference.nil? && !booking_item_reference.empty? &&
                booking_item_reference != booking_line_resource.booking_item_reference
              if booking_item = ::Yito::Model::Booking::BookingItem.get(booking_item_reference) 
                booking_line_resource.booking_item_category = booking_item.category.code if booking_item.category
                booking_line_resource.booking_item_reference = booking_item.reference
                booking_line_resource.booking_item_stock_model = booking_item.stock_model
                booking_line_resource.booking_item_stock_plate = booking_item.stock_plate
                booking_line_resource.booking_item_characteristic_1 = booking_item.characteristic_1
                booking_line_resource.booking_item_characteristic_2 = booking_item.characteristic_2
                booking_line_resource.booking_item_characteristic_3 = booking_item.characteristic_3
                booking_line_resource.booking_item_characteristic_4 = booking_item.characteristic_4              
              end
            end
            # Assign from booking request
            updated_summary = []
            updated_attributes = {}
            if data.has_key?(:booking_item_stock_model) and (!data[:booking_item_stock_model].nil? and !data[:booking_item_stock_model].empty?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_stock_model(data[:booking_item_stock_model], booking_line_resource.booking_item_stock_model) if booking_line_resource.booking_item_stock_model != data[:booking_item_stock_model]
              updated_attributes.store(:stock_model, data[:booking_item_stock_model]) if booking_line_resource.booking_item_stock_model != data[:booking_item_stock_model]
              booking_line_resource.booking_item_stock_model = data[:booking_item_stock_model]
            end
            if data.has_key?(:booking_item_stock_plate) and (!data[:booking_item_stock_plate].nil? and !data[:booking_item_stock_plate].empty?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_stock_plate(data[:booking_item_stock_plate], booking_line_resource.booking_item_stock_plate) if booking_line_resource.booking_item_stock_plate != data[:booking_item_stock_plate]
              updated_attributes.store(:stock_plate, data[:booking_item_stock_plate]) if booking_line_resource.booking_item_stock_plate != data[:booking_item_stock_plate]
              booking_line_resource.booking_item_stock_plate = data[:booking_item_stock_plate]
            end
            if data.has_key?(:booking_item_characteristic_1) and (!data[:booking_item_characteristic_1].nil? and !data[:booking_item_characteristic_1].empty?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_characteristic_1(data[:booking_item_characteristic_1], booking_line_resource.booking_item_characteristic_1) if booking_line_resource.booking_item_characteristic_1 != data[:booking_item_characteristic_1]
              updated_attributes.store(:characteristic_1, data[:booking_item_characteristic_1]) if booking_line_resource.booking_item_characteristic_1 != data[:booking_item_characteristic_1]
              booking_line_resource.booking_item_characteristic_1 = data[:booking_item_characteristic_1]
            end
            if data.has_key?(:booking_item_characteristic_2) and (!data[:booking_item_characteristic_2].nil? and !data[:booking_item_characteristic_2].empty?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_characteristic_2(data[:booking_item_characteristic_2], booking_line_resource.booking_item_characteristic_2) if booking_line_resource.booking_item_characteristic_2 != data[:booking_item_characteristic_2]
              updated_attributes.store(:characteristic_2, data[:booking_item_characteristic_2]) if booking_line_resource.booking_item_characteristic_2 != data[:booking_item_characteristic_2]
              booking_line_resource.booking_item_characteristic_2 = data[:booking_item_characteristic_2]
            end
            if data.has_key?(:booking_item_characteristic_3) and (!data[:booking_item_characteristic_3].nil? and !data[:booking_item_characteristic_3].empty?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_characteristic_3(data[:booking_item_characteristic_3], booking_line_resource.booking_item_characteristic_3) if booking_line_resource.booking_item_characteristic_3 != data[:booking_item_characteristic_3]
              updated_attributes.store(:characteristic_3, data[:booking_item_characteristic_3]) if booking_line_resource.booking_item_characteristic_3 != data[:booking_item_characteristic_3]
              booking_line_resource.booking_item_characteristic_3 = data[:booking_item_characteristic_3]
            end
            if data.has_key?(:booking_item_characteristic_4) and (!data[:booking_item_characteristic_4].nil? and !data[:booking_item_characteristic_4].empty?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_characteristic_4(data[:booking_item_characteristic_4], booking_line_resource.booking_item_characteristic_4) if booking_line_resource.booking_item_characteristic_4 != data[:booking_item_characteristic_4]
              updated_attributes.store(:characteristic_4, data[:booking_item_characteristic_4]) if booking_line_resource.booking_item_characteristic_4 != data[:booking_item_characteristic_4]
              booking_line_resource.booking_item_characteristic_4 = data[:booking_item_characteristic_4]
            end
            if data.has_key?(:km_miles_on_pickup) and (!data[:km_miles_on_pickup].nil? and data[:km_miles_on_pickup].to_i > 0)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_km_on_pickup(data[:km_miles_on_pickup], booking_line_resource.km_miles_on_pickup || '-') if booking_line_resource.km_miles_on_pickup != data[:km_miles_on_pickup]
              updated_attributes.store(:km_miles_on_pickup, data[:km_miles_on_pickup]) if booking_line_resource.km_miles_on_pickup != data[:km_miles_on_pickup]
              booking_line_resource.km_miles_on_pickup = data[:km_miles_on_pickup]
            end
            if data.has_key?(:km_miles_on_return) and (!data[:km_miles_on_return].nil? and data[:km_miles_on_return].to_i > 0)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_km_on_return(data[:km_miles_on_return], booking_line_resource.km_miles_on_return || '-') if booking_line_resource.km_miles_on_return != data[:km_miles_on_return]
              updated_attributes.store(:km_miles_on_return, data[:km_miles_on_return]) if booking_line_resource.km_miles_on_return != data[:km_miles_on_return]
              booking_line_resource.km_miles_on_return = data[:km_miles_on_return]
            end
            if data.has_key?(:resource_user_name) and (!data[:resource_user_name].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_resource_user_name(data[:resource_user_name], booking_line_resource.resource_user_name || '-') if booking_line_resource.resource_user_name != data[:resource_user_name]
              updated_attributes.store(:resource_user_name, data[:resource_user_name]) if booking_line_resource.resource_user_name != data[:resource_user_name]
              booking_line_resource.resource_user_name = data[:resource_user_name]
            end
            if data.has_key?(:resource_user_surname) and (!data[:resource_user_surname].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_resource_user_surname(data[:resource_user_surname], booking_line_resource.resource_user_surname || '-') if booking_line_resource.resource_user_surname != data[:resource_user_surname]
              updated_attributes.store(:resource_user_surname, data[:resource_user_surname]) if booking_line_resource.resource_user_surname != data[:resource_user_surname]
              booking_line_resource.resource_user_surname = data[:resource_user_surname]
            end
            if data.has_key?(:resource_user_document_id) and (!data[:resource_user_document_id].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_resource_user_document_id(data[:resource_user_document_id], booking_line_resource.resource_user_document_id || '-') if booking_line_resource.resource_user_document_id != data[:resource_user_document_id]
              updated_attributes.store(:resource_user_document_id, data[:resource_user_document_id]) if booking_line_resource.resource_user_document_id != data[:resource_user_document_id]
              booking_line_resource.resource_user_document_id = data[:resource_user_document_id]
            end
            if data.has_key?(:resource_user_phone) and (!data[:resource_user_phone].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_resource_user_phone(data[:resource_user_phone], booking_line_resource.resource_user_phone || '-') if booking_line_resource.resource_user_phone != data[:resource_user_phone]
              updated_attributes.store(:resource_user_phone, data[:resource_user_phone]) if booking_line_resource.resource_user_phone != data[:resource_user_phone]
              booking_line_resource.resource_user_phone = data[:resource_user_phone]
            end
            if data.has_key?(:resource_user_email) and (!data[:resource_user_email].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_resource_user_email(data[:resource_user_email], booking_line_resource.resource_user_email || '-') if booking_line_resource.resource_user_email != data[:resource_user_email]
              updated_attributes.store(:resource_user_email, data[:resource_user_email]) if booking_line_resource.resource_user_email != data[:resource_user_email]
              booking_line_resource.resource_user_email = data[:resource_user_email]
            end
            if data.has_key?(:customer_height) and (!data[:customer_height].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_customer_height(data[:customer_height], booking_line_resource.customer_height || '-') if booking_line_resource.customer_height != data[:customer_height]
              updated_attributes.store(:customer_height, data[:customer_height]) if booking_line_resource.customer_height != data[:customer_height]
              booking_line_resource.customer_height = data[:customer_height]
            end
            if data.has_key?(:customer_weight) and (!data[:customer_weight].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_customer_weight(data[:customer_weight], booking_line_resource.customer_weight || '-') if booking_line_resource.customer_weight != data[:customer_weight]
              updated_attributes.store(:customer_weight, data[:customer_weight]) if booking_line_resource.customer_weight != data[:customer_weight]
              booking_line_resource.customer_weight = data[:customer_weight]
            end
            if data.has_key?(:resource_user_2_name) and (!data[:resource_user_2_name].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_resource_user_2_name(data[:resource_user_2_name], booking_line_resource.resource_user_2_name || '-') if booking_line_resource.resource_user_2_name != data[:resource_user_2_name]
              updated_attributes.store(:resource_user_2_name, data[:resource_user_2_name]) if booking_line_resource.resource_user_2_name != data[:resource_user_2_name]
              booking_line_resource.resource_user_2_name = data[:resource_user_2_name]
            end
            if data.has_key?(:resource_user_2_surname) and (!data[:resource_user_2_surname].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_resource_user_2_surname(data[:resource_user_2_surname], booking_line_resource.resource_user_2_surname || '-') if booking_line_resource.resource_user_2_surname != data[:resource_user_2_surname]
              updated_attributes.store(:resource_user_2_surname, data[:resource_user_2_surname]) if booking_line_resource.resource_user_2_surname != data[:resource_user_2_surname]
              booking_line_resource.resource_user_2_surname = data[:resource_user_2_surname]
            end
            if data.has_key?(:resource_user_2_document_id) and (!data[:resource_user_2_document_id].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_resource_user_2_document_id(data[:resource_user_2_document_id], booking_line_resource.resource_user_2_document_id || '-') if booking_line_resource.resource_user_2_document_id != data[:resource_user_2_document_id]
              updated_attributes.store(:resource_user_2_document_id, data[:resource_user_2_document_id]) if booking_line_resource.resource_user_2_document_id != data[:resource_user_2_document_id]
              booking_line_resource.resource_user_2_document_id = data[:resource_user_2_document_id]
            end
            if data.has_key?(:resource_user_2_phone) and (!data[:resource_user_2_phone].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_resource_user_2_phone(data[:resource_user_2_phone], booking_line_resource.resource_user_2_phone || '-') if booking_line_resource.resource_user_2_phone != data[:resource_user_2_phone]
              updated_attributes.store(:resource_user_2_phone, data[:resource_user_2_phone]) if booking_line_resource.resource_user_2_phone != data[:resource_user_2_phone]
              booking_line_resource.resource_user_2_phone = data[:resource_user_2_phone]
            end
            if data.has_key?(:resource_user_2_email) and (!data[:resource_user_2_email].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_resource_user_2_email(data[:resource_user_2_email], booking_line_resource.resource_user_2_email || '-') if booking_line_resource.resource_user_2_email != data[:resource_user_2_email]
              updated_attributes.store(:resource_user_2_email, data[:resource_user_2_email]) if booking_line_resource.resource_user_2_email != data[:resource_user_2_email]
              booking_line_resource.resource_user_2_email = data[:resource_user_2_email]
            end
            if data.has_key?(:customer_2_height) and (!data[:customer_2_height].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_customer_2_height(data[:customer_2_height], booking_line_resource.customer_2_height || '-') if booking_line_resource.customer_2_height != data[:customer_2_height]
              updated_attributes.store(:customer_2_height, data[:customer_2_height]) if booking_line_resource.customer_2_height != data[:customer_2_height]
              booking_line_resource.customer_2_height = data[:customer_2_height]
            end
            if data.has_key?(:customer_2_weight) and (!data[:customer_2_weight].nil?)
              updated_summary << BookingDataSystem.r18n.t.booking_news_feed.updated_customer_2_weight(data[:customer_2_weight], booking_line_resource.customer_2_weight || '-') if booking_line_resource.customer_2_weight != data[:customer_2_weight]
              updated_attributes.store(:customer_2_weight, data[:customer_2_weight]) if booking_line_resource.customer_2_weight != data[:customer_2_weight]
              booking_line_resource.customer_2_weight = data[:customer_2_weight]
            end
            begin
              booking_line_resource.transaction do 
                booking_line_resource.save
                # Newsfeed
                ::Yito::Model::Newsfeed::Newsfeed.create(category: 'booking',
                                                         action: 'updated_booking_resource',
                                                         identifier: booking_line_resource.booking_line.booking.id.to_s,
                                                         description: BookingDataSystem.r18n.t.booking_news_feed.updated_booking_resource(booking_line_resource.booking_line.id, booking_line_resource.booking_line.item_id, updated_summary.join('. ')),
                                                         attributes_updated: updated_attributes.to_json)
                
              end
            rescue DataMapper::SaveFailureError => error
              logger.error "Error updating booking_line_resource #{error.resource.errors.full_messages.inspect}"
              raise error
            end
            body booking_line_resource.to_json
          else
            status 404
          end

        end   

        #
        # Delete booking line
        #
        app.delete '/api/booking/booking-line', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do
        
        end

        #
        # Delete a booking extra
        #
        app.delete '/api/booking/booking-extra', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if booking_extra = BookingDataSystem::BookingExtra.get(params[:id])
            booking = booking_extra.booking
            booking_extra.transaction do 
              booking.extras_cost -= booking_extra.extra_cost
              booking.calculate_cost(false, false)
              booking.save
              booking_extra.destroy
              # Newsfeed
              ::Yito::Model::Newsfeed::Newsfeed.create(category: 'booking',
                                                       action: 'destroyed_booking_extra',
                                                       identifier: booking.id.to_s,
                                                       description: BookingDataSystem.r18n.t.booking_news_feed.destroyed_booking_extra(booking_extra.extra_id, booking_extra.quantity),
                                                       attributes_updated: {extras_cost: booking.extras_cost, total_cost: booking.total_cost}.merge({booking: booking.newsfeed_summary}).to_json)
            end
            booking.reload
            content_type :json
            booking.to_json
          else
            logger.error("Booking extra #{params[:id]} not found")
            status 404
          end

        end

        #
        # Register a booking charge
        #
        app.post '/api/booking/charge', :allowed_usergroups => ['bookings_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys!

          if booking = BookingDataSystem::Booking.get(data[:id])

            booking.transaction do
              charge = Payments::Charge.new
              charge.date = data[:date]
              charge.amount = data[:amount]
              charge.payment_method_id = data[:payment_method_id]
              charge.status = :pending
              charge.currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
              charge.save
              booking_charge = BookingDataSystem::BookingCharge.new
              booking_charge.booking = booking
              booking_charge.charge = charge
              booking_charge.save
              charge.update(:status => :done)
              # Newsfeed
              ::Yito::Model::Newsfeed::Newsfeed.create(category: 'booking',
                                                       action: 'add_booking_charge',
                                                       identifier: booking.id.to_s,
                                                       description: BookingDataSystem.r18n.t.booking_news_feed.added_booking_charge("%.2f" % charge.amount, charge.payment_method_id),
                                                       attributes_updated: {date: charge.date, amount: charge.amount,
                                                                            payment_method_id: charge.payment_method_id}.merge({booking: booking.newsfeed_summary}).to_json)
              booking.reload
            end
            content_type :json
            status 200
            booking.to_json
          else
            status 404
          end

        end

        #
        # Delete a booking charge
        #
        app.delete '/api/booking/booking-charge/?*', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do
          
          if booking_charge = BookingDataSystem::BookingCharge.first(:booking_id => params[:booking_id],
                                                                     :charge_id => params[:charge_id])
            booking = booking_charge.booking
            old_total_paid = booking.total_paid
            old_total_pending = booking.total_pending
            charge = booking_charge.charge
            booking_charge.transaction do
              if charge.status == :done 
                booking.total_paid -= charge.amount
                booking.total_pending += charge.amount
                booking.save
              end
              charge.destroy
              booking_charge.destroy
              # Newsfeed
              ::Yito::Model::Newsfeed::Newsfeed.create(category: 'booking',
                                                       action: 'destroyed_booking_charge',
                                                       identifier: booking.id.to_s,
                                                       description: BookingDataSystem.r18n.t.booking_news_feed.destroyed_booking_charge("%.2f" % charge.amount, charge.payment_method_id),
                                                       attributes_updated: {total_paid: booking.total_paid, total_pending: booking.total_pending}.merge({booking: booking.newsfeed_summary}).to_json)
            end
            booking.reload
            content_type :json
            booking.to_json
          else
            logger.error("Booking charge #{params[:charge_id]} for #{params[:booking_id]} not found")
            status 404
          end

        end

        # ------------ Send the notification emails ----------------------

        #
        # Request received
        #
        app.post '/api/booking/send-customer-req-notification/:id' , :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:id].to_i) and 
             booking.status != :cancelled
            booking.notify_request_to_customer(true)
            content_type :json
            booking.to_json
          else
            status 404
          end

        end

        #
        # Request received (with online payment)
        #
        app.post '/api/booking/send-customer-req-notification-pay/:id' , :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:id].to_i) and 
             booking.status != :cancelled and 
             booking.pay_now
            booking.notify_request_to_customer_pay_now(true)
            content_type :json
            booking.to_json
          else
            status 404
          end

        end

        #
        # Request confirmed
        #
        app.post '/api/booking/send-customer-conf-notification/:id' , :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:id].to_i) and
             booking.status != :pending_confirmation and 
             booking.status != :cancelled
            booking.notify_customer(true)
            content_type :json
            booking.to_json
          else
            status 404
          end

        end        

        #
        # Payment enabled
        #
        app.post '/api/booking/send-customer-pay-enabled/:id' , :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:id].to_i) and
             booking.status != :cancelled
            booking.notify_customer_payment_enabled(true)
            content_type :json
            booking.to_json
          else
            status 404
          end

        end

        # -------------------------- External invoice -------------------------------

        app.get '/api/bookings/next-external-invoice-number', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do
          content_type :json
          value = (BookingDataSystem::Booking.max_external_invoice_number.to_i + 1)
          value.to_json
        end

      end

    end #BookingManagementRESTApi
  end #YSD
end #Sinatra