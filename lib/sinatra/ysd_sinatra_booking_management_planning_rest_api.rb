
module Sinatra
  module YSD
    module BookingManagementPlanningRESTApi

      def self.registered(app)

        # ------------------------------ QUERYING DATA FOR THE PLANNING ---------------------------------------------

        #
        # Planning summary
        # -----------------------------------------------------------------------------------------------------------
        #
        # Get the planning information (reservations and stock blockings) to fill the grid
        #
        # Request parameters::
        #
        # from::
        #   Date from
        # to::
        #   Date to
        # product::
        #   category code. Show resources that belongs to the category
        # reference::
        #   item reference. Show only the selected resource
        #
        # Returns::
        #
        # references -> Hash with the references. The key is the stock reference and the value is the category
        #          {
        #            "K1-01" : "K1"
        #          }
        # result -> Array with the reservations and stock blockings to show in the planning
        #          [
        #              {
        #               "booking_item_reference":"K1-01",
        #               "item_id":"K1",
        #               "requested_item_id":"K1",
        #               "id":22,
        #               "origin":"booking",
        #               "date_from":"2018-08-01",
        #               "time_from":"10:00",
        #               "date_to":"2018-08-13",
        #               "time_to":"20:00",
        #               "days":12,
        #               "title":"Cersei Lannister",
        #               "detail":null,
        #               "id2":50,
        #               "planning_color":"#66ff66",
        #               "notes":null,
        #               "confirmed":0,
        #               "auto_assigned_item_reference": false
        #               }
        #          ]
        #
        app.get '/api/booking/planning-summary/?*', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          today = Date.today
          @date_from = Date.civil(today.year, today.month, 1)
          @date_to = Date.civil(today.year, today.month, -1)

          if params[:from]
            begin
              @date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              @date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("date not valid #{params[:to]}")
            end
          end

          @options = {}

          # automatic management pending reservations
          automatic_management_pending_reservations = SystemConfiguration::Variable.get_value('booking.assignation.automatically_manage_pending_of_confirmation', 'true').to_bool
          @options.store(:include_future_pending_confirmation, true) if automatic_management_pending_reservations

          # Category or reference
          if params[:reference]
            @options.merge!({mode: :stock, reference: params[:reference]})
          elsif params[:product]
            @options.merge!({mode: :product, product: params[:product]})
          end

          result = BookingDataSystem::Booking.planning(@date_from, @date_to, @options)

          content_type :json
          result.to_json
        end

        # -------------------------- SEARCH FOR NEW RESERVATION / STOCK BLOCKING ------------------------------------

        #
        # Search for products in planning to create a new reservation or stock blocking
        # -----------------------------------------------------------------------------------------------------------
        #
        # Search availiability to create a new reservation or stock blocking in the planning
        #
        # Request parameters::
        #
        # from::
        #   Date from
        # to::
        #   Date to
        # product::
        #   category code. Show resources that belongs to the category
        # reference::
        #   item reference. Show only the selected resource
        #
        app.post '/api/booking/planning/search', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys

          # TODO Check parameters
          date_from = time_from = date_to = time_to = pickup_place = return_place = number_of_adults = number_of_children =
            driver_age_rule_id = sales_channel_code = rental_location_code = nil

          if model_request[:date_from] && model_request[:date_to]
            # Retrieve date/time from - to
            date_from = DateTime.strptime(model_request[:date_from],"%d/%m/%Y")
            time_from = model_request[:time_from]
            date_to = DateTime.strptime(model_request[:date_to],"%d/%m/%Y")
            time_to = model_request[:time_to]
            # Retrieve pickup/return place
            pickup_place, custom_pickup_place, pickup_place_customer_translation,
                return_place, custom_return_place, return_place_customer_translation, rental_location_code = request_pickup_return_place(model_request)             
            # Retrieve number of adutls and children
            number_of_adults = model_request[:number_of_adults] if model_request.has_key?(:number_of_adults)
            number_of_children = model_request[:number_of_children] if model_request.has_key?(:number_of_childen)
            # Retrieve driver age rule
            driver_age_rule_id = model_request[:driver_age_rule] if model_request.has_key?(:driver_age_rule)
            # Retrieve sales channel
            sales_channel_code = model_request[:sales_channel_code] if model_request.has_key?(:sales_channel_code)
            sales_channel_code = nil if sales_channel_code and sales_channel_code.empty?
            # Retrieve promotion code
            promotion_code = model_request[:promotion_code] if model_request.has_key?(:promotion_code)
            promotion_code = nil if promotion_code and promotion_code.empty?
          else
            content_type :json
            status 422
            {error: 'Invalid request. data_from and date_to are required.'}.to_json
            halt
          end

          # Calculate the number of days
          data = BookingDataSystem::Booking.calculate_days(date_from, time_from, date_to, time_to)

          # Prepare the products
          products = ::Yito::Model::Booking::BookingCategory.search(rental_location_code,
                                                                    date_from,
                                                                    time_from,
                                                                    date_to,
                                                                    time_to,
                                                                    data[:days],
                                                                    {
                                                                        locale: settings.default_language,
                                                                        full_information: true,
                                                                        product_code: nil,
                                                                        web_public: false,
                                                                        sales_channel_code: sales_channel_code,
                                                                        apply_promotion_code: !promotion_code.nil?,
                                                                        promotion_code: promotion_code,
                                                                        include_stock: true})

          content_type :json
          {products: products}.to_json

        end

        # --------------------------------- REASSIGNATION --------------------------------------------------------

        #
        # Assign or reassign a reservation or prereservation
        # --------------------------------------------------------------------------------------------------------
        #
        # RequestParams::
        #
        # type::
        #   Indicates if a booking or a prereservation
        #   'booking' or 'prereservation'
        #
        # id::
        #   If the type is 'booking' the booking line resource id
        #   If the type is 'prereservation' is the booking line reservation id
        #
        # resource::
        #   The reference of the stock item to be reassigned
        #
        # Returns::
        #
        # A JSON with the assignation data
        #
        # { "booking_item_reference":
        #   "item_id":
        #   "requested_item_id":
        #   "id":
        #   "origin":
        #   "date_from":
        #   "time_from":
        #   "date_to":
        #   "time_to":
        #   "days":
        #   "title":
        #   "detail":
        #   "id2":
        #   "planning_color":
        #   "notes":
        #   "confirmed":
        # }
        #
        app.post '/api/booking/planning/reassign', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          id = params[:id]
          resource = params[:resource]
          type = params[:type]

          if type == 'booking'
            if booking_line_resource = BookingDataSystem::BookingLineResource.get(id)
              if booking_item = ::Yito::Model::Booking::BookingItem.get(resource)
                booking_line_resource.transaction do
                  booking_line_resource.assign_resource(resource)
                end
                booking = booking_line_resource.booking_line.booking
                booking_line = booking_line_resource.booking_line
                result = {"booking_item_reference": booking_line_resource.booking_item_reference,
                          "item_id": booking_line_resource.booking_item_category,
                          "requested_item_id": booking_line.item_id,
                          "id": booking.id,
                          "origin": "booking",
                          "date_from": booking.date_from.strftime("%Y-%m-%d"),
                          "time_from": booking.time_from,
                          "date_to": booking.date_to.strftime("%Y-%m-%d"),
                          "time_to":booking.time_to,
                          "days": booking.days,
                          "title": "#{booking.customer_name} #{booking.customer_surname}",
                          "detail":"#{booking_line_resource.resource_user_name} #{booking_line_resource.resource_user_surname} #{booking_line_resource.customer_height} #{booking_line_resource.customer_weight}",
                          "id2": booking_line_resource.id,
                          "planning_color": booking.planning_color,
                          "notes": booking.notes,
                          "confirmed": ([:confirmed, :in_progress, :done].include?(booking.status) ? 1 : 0),
                          "auto_assigned_item_reference": false
                         }
                status 200
                content_type :json
                result.to_json
              else
                status 404
              end
            else
              status 404
            end
          elsif type == 'prereservation'
            if prereservation_line = BookingDataSystem::BookingPrereservationLine.get(id)
              if booking_item = ::Yito::Model::Booking::BookingItem.get(resource)
                prereservation_line.booking_item_category = booking_item.category.code if booking_item.category
                prereservation_line.booking_item_reference = booking_item.reference
                prereservation_line.save
                prereservation = prereservation_line.prereservation
                result = {
                 "booking_item_reference": prereservation_line.booking_item_reference,
                 "item_id": prereservation_line.booking_item_category,
                 "requested_item_id": prereservation_line.booking_item_category,
                 "id": prereservation.id,
                 "origin": "prereservation",
                 "date_from": prereservation.date_from.strftime("%Y-%m-%d"),
                 "time_from": prereservation.time_from,
                 "date_to": prereservation.date_to.strftime("%Y-%m-%d"),
                 "time_to": prereservation.time_to,
                 "days": prereservation.days,
                 "title": prereservation.title,
                 "detail": prereservation.notes,
                 "id2": prereservation_line.id,
                 "planning_color": prereservation.planning_color,
                 "notes": prereservation.notes,
                 "confirmed": 1,
                 "auto_assigned_item_reference": false
                }
                status 200
                content_type :json
                result.to_json
              else
                status 404
              end
            else
              status 404
            end
          else
            status 404
          end

        end

        # -------------------------- MANAGE BOOKINGS IN PLANNING ----------------------------------------------------

        #
        # Load a reservation
        # -----------------------------------------------------------------------------------------------------------
        #
        # Load a reservation to update the requested products in the planning
        #
        # Request parameters::
        #
        # id::
        #   The reservation id
        #
        # Returns::
        #   A JSON with the following attributes
        #
        #   booking : The reservation information
        #   products: Products search to get availability and prices
        #   extras: Extras search to get availability and prices
        #
        app.get '/api/booking/planning/booking/:id', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if @booking = BookingDataSystem::Booking.get(params[:id])

            # Prepare the products
            products = ::Yito::Model::Booking::BookingCategory.search(@booking.rental_location_code,
                                                                      @booking.date_from,
                                                                      @booking.time_from,
                                                                      @booking.date_to,
                                                                      @booking.time_to,
                                                                      @booking.days,
                                                                      { locale: settings.default_language,
                                                                        full_information: true,
                                                                        product_code: nil,
                                                                        web_public: false,
                                                                        sales_channel_code: (@booking.sales_channel_code.nil? or @booking.sales_channel_code.empty?) ? nil : @booking.sales_channel_code,
                                                                        apply_promotion_code: (@booking.promotion_code.nil? ? false : true),
                                                                        promotion_code: @booking.promotion_code,
                                                                        include_stock: true})

            # Prepare the extras
            extras = ::Yito::Model::Booking::RentingExtraSearch.search(@booking.date_from,
                                                                       @booking.date_to,
                                                                       @booking.days,
                                                                       settings.default_language)
            data = {
                booking: {id: @booking.id,
                          date_from: SystemConfiguration::Settings.instance.format_date(@booking.date_from, :short, session[:locale]),
                          time_from: @booking.time_from,
                          date_to: SystemConfiguration::Settings.instance.format_date(@booking.date_to, :short, session[:locale]),
                          time_to: @booking.time_to,
                          pickup_place: @booking.pickup_place,
                          return_place: @booking.return_place,
                          booking_lines: @booking.booking_lines,
                          booking_extras: @booking.booking_extras,
                          title: "#{@booking.customer_name} #{@booking.customer_surname}"
                         },
                products: products,
                extras: extras
              }

            content_type :json
            data.to_json
          else
            status 404
          end

        end

        #
        # Create a reservation in the planning
        # ------------------------------------------------------------------------------------------------------------
        #
        app.post '/api/booking/planning/booking', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys

          BookingDataSystem::Booking.transaction do
            begin
              # Retrieve date/time from - to
              date_from = DateTime.strptime(model_request[:date_from],"%d/%m/%Y")
              time_from = model_request[:time_from]
              date_to = DateTime.strptime(model_request[:date_to],"%d/%m/%Y")
              time_to = model_request[:time_to]
              # Retrieve pickup/return place
              pickup_place, custom_pickup_place, pickup_place_customer_translation,
                  return_place, custom_return_place, return_place_customer_translation, rental_location_code = request_pickup_return_place(model_request)
              # Retrieve number of adutls and children
              number_of_adults = model_request[:number_of_adults] if model_request.has_key?(:number_of_adults)
              number_of_children = model_request[:number_of_children] if model_request.has_key?(:number_of_childen)
              # Retrieve driver age rule
              driver_age_rule_id = model_request[:driver_age_rule] if model_request.has_key?(:driver_age_rule)
              # Retrieve sales channel
              sales_channel_code = model_request[:sales_channel_code] if model_request.has_key?(:sales_channel_code)
              sales_channel_code = nil if sales_channel_code and sales_channel_code.empty?

              @booking = BookingDataSystem::Booking.create(date_from: date_from,
                                                           time_from: time_from,
                                                           date_to: date_to,
                                                           time_to: time_to,
                                                           pickup_place: pickup_place,
                                                           custom_pickup_place: custom_pickup_place,
                                                           pickup_place_customer_translation: pickup_place_customer_translation,
                                                           return_place: return_place,
                                                           custom_return_place: custom_return_place,
                                                           return_place_customer_translation: return_place_customer_translation,
                                                           customer_name: model_request[:customer_name],
                                                           customer_surname: model_request[:customer_surname],
                                                           customer_phone: model_request[:customer_phone],
                                                           customer_mobile_phone: model_request[:customer_mobile_phone],
                                                           customer_email: model_request[:customer_email],
                                                           planning_color: '#f3b760',
                                                           created_by_manager: true) #TODO pass the planning color

              days_calculus = BookingDataSystem::Booking.calculate_days(date_from, time_from, date_to, time_to)
              
              if (days_calculus and days_calculus[:valid])
                @booking.days = days_calculus[:days]
                @booking.date_to_price_calculation = days_calculus[:date_to_price_calculation]
              end

              model_request[:products].each do |code, quantity|
                @booking.add_booking_line(code, quantity.to_i)
              end

              #
              # Assign the references
              #
              if model_request.has_key?(:references)
                # Process
                references = model_request[:references]
                references_categories = references.keys
                references_categories.each do |category|
                  blrs = @booking.booking_line_resources.to_a.select { |blr| blr.booking_line.item_id.to_s == category.to_s}
                  idx = 0
                  references[category].each do |reference|
                    blrs[idx].assign_resource(reference) if idx < blrs.size
                    idx += 1
                  end
                end
              end

              @booking.confirm!

              @booking.reload

              # Build the result to update the planning data
              result = @booking.booking_line_resources.inject([]) do |result, value|
                result <<
                    {"booking_item_reference": value.booking_item_reference,
                     "item_id": value.booking_item_category,
                     "requested_item_id": value.booking_line.item_id,
                     "id": @booking.id,
                     "origin": "booking",
                     "date_from": @booking.date_from.strftime("%Y-%m-%d"),
                     "time_from": @booking.time_from,
                     "date_to": @booking.date_to.strftime("%Y-%m-%d"),
                     "time_to": @booking.time_to,
                     "days": @booking.days,
                     "title": "#{@booking.customer_name} #{@booking.customer_surname}",
                     "detail":"#{value.resource_user_name} #{value.resource_user_surname} #{value.customer_height} #{value.customer_weight}",
                     "id2": value.id,
                     "planning_color": @booking.planning_color,
                     "notes": @booking.notes,
                     "confirmed": ([:confirmed, :in_progress, :done].include?(@booking.status) ? 1 : 0),
                     "auto_assigned_item_reference": false
                    }
              end
              content_type :json
              result.to_json

            rescue  DataMapper::SaveFailureError => error
              logger.error "#{error.resource.errors.full_messages.inspect}"
              raise error
            end
          end
        end

        #
        # Update a reservation in the planning
        # -----------------------------------------------------------------------------------------------------------
        #
        app.put '/api/booking/planning/booking/:id', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))

          if @booking = BookingDataSystem::Booking.get(params[:id])
            begin

              @booking.transaction do
                data.each do |product_code, quantity|
                  quantity = quantity.to_i
                  booking_lines = @booking.booking_lines.select do |booking_line|
                    booking_line.item_id == product_code
                  end
                  # Update the booking line
                  if booking_line = booking_lines.first
                    if quantity == 0
                      @booking.destroy_booking_line(product_code)
                    elsif quantity != booking_line.quantity
                      booking_line.update_quantity(quantity)
                    end
                  else
                    # Create a new booking line
                    @booking.add_booking_line(product_code, quantity) unless quantity == 0
                  end
                end
                # Automatic stock assignation
                automatic_resource_assignation = SystemConfiguration::Variable.get_value('booking.assignation.automatic_resource_assignation', 'false').to_bool
                if automatic_resource_assignation and @booking.confirmed?
                  @booking.assign_available_stock
                end
                @booking.reload
                # Build the result to update the planning data
                result = @booking.booking_line_resources.inject([]) do |result, value|
                  result <<
                      {"booking_item_reference": value.booking_item_reference,
                       "item_id": value.booking_item_category,
                       "requested_item_id": value.booking_line.item_id,
                       "id": @booking.id,
                       "origin": "booking",
                       "date_from": @booking.date_from.strftime("%Y-%m-%d"),
                       "time_from": @booking.time_from,
                       "date_to": @booking.date_to.strftime("%Y-%m-%d"),
                       "time_to": @booking.time_to,
                       "days": @booking.days,
                       "title": "#{@booking.customer_name} #{@booking.customer_surname}",
                       "detail":"#{value.resource_user_name} #{value.resource_user_surname} #{value.customer_height} #{value.customer_weight}",
                       "id2": value.id,
                       "planning_color": @booking.planning_color,
                       "notes": @booking.notes,
                       "confirmed": ([:confirmed, :in_progress, :done].include?(@booking.status) ? 1 : 0),
                       "auto_assigned_item_reference": false
                      }
                end
                content_type :json
                result.to_json
              end
            rescue DataMapper::SaveFailureError => error
              logger.error "Error updating booking #{error.resource.errors.full_messages.inspect}"
              raise error
            end

          else
            status 404
          end


        end

        # -------------------------- MANAGE STOCK BLOCKINGS IN PLANNING ------------------------------------------

        #
        # Load a stock blocking
        # -----------------------------------------------------------------------------------------------------------
        #
        # Request parameters::
        #
        # id::
        #   The stock blocking id
        #
        app.get '/api/booking/planning/prereservation/:id', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if @prereservation = BookingDataSystem::BookingPrereservation.get(params[:id])

            # Prepare the products
            products = ::Yito::Model::Booking::BookingCategory.search(@prereservation.rental_location_code, # TO CHECK
                                                                      @prereservation.date_from,
                                                                      @prereservation.time_from,
                                                                      @prereservation.date_to,
                                                                      @prereservation.time_to,
                                                                      @prereservation.days,
                                                                      { locale: settings.default_language,
                                                                        full_information: true,
                                                                        product_code: nil,
                                                                        web_public: false,
                                                                        include_stock: true,
                                                                        apply_promotion_code: false,
                                                                        promotion_code: nil})

            data = {
                prereservation: {id: @prereservation.id,
                          date_from: SystemConfiguration::Settings.instance.format_date(@prereservation.date_from, :short, session[:locale]),
                          time_from: @prereservation.time_from,
                          date_to: SystemConfiguration::Settings.instance.format_date(@prereservation.date_to, :short, session[:locale]),
                          time_to: @prereservation.time_to,
                          prereservation_lines: @prereservation.prereservation_lines,
                          title: @prereservation.title,
                          notes: @prereservation.notes
                          },
                products: products
            }

            content_type :json
            data.to_json
          else
            status 404
          end

        end

        #
        # Create a stock-blocking
        # ------------------------------------------------------------------------------------------------------------
        #
        app.post '/api/booking/planning/prereservation', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys

          BookingDataSystem::BookingPrereservation.transaction do
            begin
              # Retrieve date/time from - to
              date_from = DateTime.strptime(model_request[:date_from],"%d/%m/%Y")
              time_from = model_request[:time_from]
              date_to = DateTime.strptime(model_request[:date_to],"%d/%m/%Y")
              time_to = model_request[:time_to]
              title = model_request[:title]
              notes = model_request[:notes]

              @prereservation = BookingDataSystem::BookingPrereservation.new(date_from: date_from,
                                                                             time_from: time_from,
                                                                             date_to: date_to,
                                                                             time_to: time_to,
                                                                             planning_color: '#cccccc',
                                                                             title: title,
                                                                             notes: notes) #TODO pass the planning color

              #
              # Assign the references
              #
              if model_request.has_key?(:references)
                # Process
                references = model_request[:references]
                references.each do |category, references|
                  if references.is_a?(Array)
                    references.each do |reference|
                      @prereservation.prereservation_lines << BookingDataSystem::BookingPrereservationLine.new(booking_item_category: category,
                                                                                                               booking_item_reference: reference)
                    end
                  elsif references.is_a?(String)
                    @prereservation.prereservation_lines << BookingDataSystem::BookingPrereservationLine.new(booking_item_category: category,
                                                                                                             booking_item_reference: references)
                  end
                end
              end

              @prereservation.save

              # Build the result to update the planning data
              result = @prereservation.prereservation_lines.inject([]) do |result, value|
                result <<
                    {"booking_item_reference": value.booking_item_reference,
                     "item_id": value.booking_item_category,
                     "requested_item_id": value.booking_item_category,
                     "id": @prereservation.id,
                     "origin": "prereservation",
                     "date_from": @prereservation.date_from.strftime("%Y-%m-%d"),
                     "time_from": @prereservation.time_from,
                     "date_to": @prereservation.date_to.strftime("%Y-%m-%d"),
                     "time_to": @prereservation.time_to,
                     "days": @prereservation.days,
                     "title": @prereservation.title,
                     "detail": @prereservation.notes,
                     "id2": value.id,
                     "planning_color": @prereservation.planning_color,
                     "notes": @prereservation.notes,
                     "confirmed": 1,
                     "auto_assigned_item_reference": false
                    }
              end
              content_type :json
              result.to_json

            rescue  DataMapper::SaveFailureError => error
              logger.error "#{error.resource.errors.full_messages.inspect}"
              raise error
            end
          end
        end

        #
        # Update a stock blocking
        # -----------------------------------------------------------------------------------------------------------
        #
        # Request parameters::
        #
        # id::
        #   The stock blocking id
        #
        app.put '/api/booking/planning/prereservation/:id', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys

          if @prereservation = BookingDataSystem::BookingPrereservation.get(params[:id])
            begin
              @prereservation.transaction do
                  @prereservation.title = model_request[:title] if model_request.has_key?(:title)
                  @prereservation.notes = model_request[:notes] if model_request.has_key?(:notes)
                  if model_request.has_key?(:references)
                    model_request[:references].each do |category, resources|
                      resources.each do |resource|
                        @prereservation.prereservation_lines << BookingDataSystem::BookingPrereservationLine.new(booking_item_category: category, booking_item_reference: resource)
                      end
                    end
                  end
                  @prereservation.save
                  # Build the result to update the planning data
                  result = @prereservation.prereservation_lines.inject([]) do |result, value|
                    result <<
                        {"booking_item_reference": value.booking_item_reference,
                         "item_id": value.booking_item_category,
                         "requested_item_id": value.booking_item_category,
                         "id": @prereservation.id,
                         "origin": "prereservation",
                         "date_from": @prereservation.date_from.strftime("%Y-%m-%d"),
                         "time_from": @prereservation.time_from,
                         "date_to": @prereservation.date_to.strftime("%Y-%m-%d"),
                         "time_to": @prereservation.time_to,
                         "days": @prereservation.days,
                         "title": @prereservation.title,
                         "detail": @prereservation.notes,
                         "id2": value.id,
                         "planning_color": @prereservation.planning_color,
                         "notes": @prereservation.notes,
                         "confirmed": 1,
                         "auto_assigned_item_reference": false
                        }
                  end
                  content_type :json
                  result.to_json
              end
            rescue  DataMapper::SaveFailureError => error
              logger.error "#{error.resource.errors.full_messages.inspect}"
              raise error
            end

          end

        end

        #
        # Delete a stock blocking line
        # -----------------------------------------------------------------------------------------------------------
        #
        # Request parameters::
        #
        # id::
        #   The stock blocking line id
        #
        app.delete '/api/booking/planning/prereservation-line/:id', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if @prereservation_line = BookingDataSystem::BookingPrereservationLine.get(params[:id].to_i)
            BookingDataSystem::BookingPrereservation.transaction do
              begin
                # Destroy the line
                @prereservation_line.destroy
                # Check if the pre-reservation is empty to destroy it
                @prereservation_line.prereservation.reload
                if @prereservation_line.prereservation.prereservation_lines.size == 0
                  @prereservation_line.prereservation.destroy
                end
              rescue  DataMapper::SaveFailureError => error
                logger.error "#{error.resource.errors.full_messages.inspect}"
                raise error
              end
            end
          else
            status 404
          end

        end

      end
    end
  end
end