module Sinatra
  module YitoExtension

    # ------------------------------------------- HELPER -------------------------------------------------------

    module BookingNewReservationRESTApiHelper

      #
      # Build the shopping cart (with products and extras) to be served
      #
      def backend_shopping_cart_to_json(shopping_cart)

        # Prepare the shopping cart
        only = [:free_access_id, :date_from, :time_from, :date_to, :time_to, :pickup_place, :return_place, :days,
                :item_cost, :extras_cost, :time_from_cost, :time_to_cost, :product_deposit_cost, :total_deposit, 
                :category_supplement_1_cost, :category_supplement_2_cost, :category_supplement_3_cost,
                :supplement_1_cost, :supplement_2_cost, :supplement_3_cost,
                :total_cost,
                :booking_amount, :pickup_place_cost, :return_place_cost,
                :customer_name, :customer_surname, :customer_email, :customer_phone, :customer_mobile_phone, :customer_document_id,
                :driver_age, :driver_driving_license_years, :driver_under_age, :driver_age_allowed, :driver_age_cost, :driver_age_deposit,
                :promotion_code, :comments, :rental_location_code ]
        relationships = {}
        relationships.store(:extras, {})
        relationships.store(:items, {:include => [:item_resources]})

        sc_json = shopping_cart.to_json(only: only, relationships: relationships)

        locale = session[:locale]#locale_to_translate_into
        
        # Prepare the products
        p_json = ::Yito::Model::Booking::BookingCategory.search(shopping_cart.rental_location_code,
                                                                shopping_cart.date_from,
                                                                shopping_cart.time_from,
                                                                shopping_cart.date_to,
                                                                shopping_cart.time_to,
                                                                shopping_cart.days,
                                                          { locale: locale,
                                                                   full_information: true,
                                                                   product_code: nil,
                                                                   web_public: false,
                                                                   sales_channel_code: shopping_cart.sales_channel_code,
                                                                   apply_promotion_code: (shopping_cart.promotion_code and !shopping_cart.promotion_code.empty?) ? true : false,
                                                                   promotion_code: shopping_cart.promotion_code
                                                                }).to_json

        # Prepare the extras
        e_json = ::Yito::Model::Booking::RentingExtraSearch.search(shopping_cart.date_from,
                                                                   shopping_cart.date_to, shopping_cart.days, locale,
                                                                   nil,
                                                                   shopping_cart.items.map {|item| item.item_id}).to_json

        # Join all the data togheter
        "{\"shopping_cart\": #{sc_json}, \"products\": #{p_json}, \"extras\": #{e_json} }"

      end
    end


    # ------------------------------------------- EXTENSION -------------------------------------------------------

    module BookingNewReservationRESTApi

      def self.registered(app)

        #
        # Create/Update the renting shopping cart
        #
        app.post '/api/booking/new-reservation/select-dates', :allowed_usergroups => ['booking_manager', 'booking_operator','staff'] do

          # Extract the data parameters
          begin
            request.body.rewind
            model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
          rescue JSON::ParserError
            content_type :json
            status 422
            {error: 'Invalid request. Expected a JSON with data params'}.to_json
            halt
          end

          # TODO Check parameters
          date_from = time_from = date_to = time_to = pickup_place = return_place = number_of_adults = number_of_children =
          driver_age_rule_id = sales_channel_code = promotion_code = rental_location_code = nil

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

          # Retrieve the shopping cart
          shopping_cart = nil
          if session.has_key?('back_office_shopping_cart_renting_id')
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session['back_office_shopping_cart_renting_id'])
          end

          # Updates or creates the shopping cart with the new dates or do create a new one if it does not exist
          if shopping_cart
            shopping_cart.change_selection_data(date_from, time_from,
                                                date_to, time_to,
                                                pickup_place, custom_pickup_place,
                                                return_place, custom_return_place,
                                                number_of_adults, number_of_children,
                                                driver_age_rule_id, sales_channel_code,
                                                promotion_code)
          else
            shopping_cart =::Yito::Model::Booking::ShoppingCartRenting.create(
                date_from: date_from, time_from: time_from,
                date_to: date_to, time_to: time_to,
                pickup_place: pickup_place,
                custom_pickup_place: custom_pickup_place,
                pickup_place_customer_translation: pickup_place_customer_translation,
                return_place: return_place,
                custom_return_place: custom_return_place,
                return_place_customer_translation: return_place_customer_translation,
                number_of_adults: number_of_adults, number_of_children: number_of_children,
                driver_age_rule_id: driver_age_rule_id,
                sales_channel_code: sales_channel_code,
                promotion_code: promotion_code,
                customer_language: settings.default_language)
            session['back_office_shopping_cart_renting_id'] = shopping_cart.id
          end

          # Return the shopping cart
          if shopping_cart
            content_type 'json'
            status 200
            backend_shopping_cart_to_json(shopping_cart)
          else
            logger.error "No shopping cart"
            content_type 'json'
            status 404
            {error: 'Shopping cart not found'}.to_json
          end

        end

        #
        # Set/add the product
        #
        app.post '/api/booking/new-reservation/set-product', :allowed_usergroups => ['booking_manager','booking_operator','staff'] do

          # Extract the data parameters
          begin
            request.body.rewind
            model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
          rescue JSON::ParserError
            halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
          end
          product_code = model_request[:product]
          quantity = model_request[:quantity] || 1

          # TODO : Validate it's a valid product

          # Retrieve the shopping cart
          if session.has_key?('back_office_shopping_cart_renting_id')
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session['back_office_shopping_cart_renting_id'])
          end

          # Do the process
          if shopping_cart
            product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
            multiple_products = (product_family.frontend == :shopcart)
            shopping_cart.set_item(product_code, quantity, multiple_products)
            content_type 'json'
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "Shopping cart does not exist"
            halt 404, {error: 'Shopping cart not found'}.to_json
          end

        end

        #
        # Add o Remove extra
        #
        app.post '/api/booking/new-reservation/set-extra', :allowed_usergroups => ['booking_manager','booking_operator','staff'] do

          # Extract the data parameters
          begin
            request.body.rewind
            model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
          rescue JSON::ParserError
            halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
          end
          extra_code = model_request[:extra]
          extra_quantity = model_request[:quantity].to_i || 1

          # TODO : Validate it's a valid extra

          # Retrieve the shopping cart
          shopping_cart = if session.has_key?('back_office_shopping_cart_renting_id')
                            ::Yito::Model::Booking::ShoppingCartRenting.get(session['back_office_shopping_cart_renting_id'])
                          end

          # Do the process
          if shopping_cart
            if extra_quantity > 0
              shopping_cart.set_extra(extra_code, extra_quantity)
            else
              shopping_cart.remove_extra(extra_code)
            end
            content_type :json
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "Shopping cart does not exist"
            halt 404, {error: 'Shopping cart not found'}.to_json
          end

        end

        #
        # Confirm reservation
        #
        app.post '/api/booking/new-reservation/checkout', :allowed_usergroups => ['booking_manager','booking_operator','staff'] do

          # Request data
          request.body.rewind
          request_data = JSON.parse(URI.unescape(request.body.read))

          # Retrieve the shopping cart
          shopping_cart = if session.has_key?('back_office_shopping_cart_renting_id')
                            ::Yito::Model::Booking::ShoppingCartRenting.get(session['back_office_shopping_cart_renting_id'])
                          end

          # Do the process
          if shopping_cart
            # Basic data: customer and comments
            shopping_cart.customer_name = request_data['customer_name'] || request_data['driver_name']
            shopping_cart.customer_surname = request_data['customer_surname'] || request_data['driver_surname']
            shopping_cart.customer_email = request_data['customer_email']
            shopping_cart.customer_phone = request_data['customer_phone']
            shopping_cart.customer_mobile_phone = request_data['customer_mobile_phone']
            shopping_cart.comments = request_data['comments']
            # Number of adults/children (accomodation)
            shopping_cart.number_of_adults = request_data['number_of_adults'] if request_data.has_key?('number_of_adults')
            shopping_cart.number_of_children = request_data['number_of_children'] if request_data.has_key?('number_of_children')

            begin
              shopping_cart.save
            rescue DataMapper::SaveFailureError => error
              logger.error "Error saving shopping cart. #{error} Details: #{error.resource.errors.full_messages.inspect}"
              halt 422, {error: error.resource.errors.full_messages}.to_json
            end

            logger.debug "Updated shopping cart"

            # Creates the booking
            booking = nil
            begin
              automatic_confirmation = SystemConfiguration::Variable.get_value('booking.automatic_confirm_backoffice_reservation_request', 'false').to_bool
              booking = BookingDataSystem::Booking.create_from_shopping_cart(shopping_cart,
                                                                             request.env["HTTP_USER_AGENT"],
                                                                             true,
                                                                             !automatic_confirmation)
              shopping_cart.destroy # Destroy the converted shopping cart
            rescue DataMapper::SaveFailureError => error
              logger.error "Error creating booking from shopping cart #{error.inspect}. Details: #{error.resource.errors.full_messages.inspect}"
              halt 422, {error: error.resource.errors.full_messages}.to_json
            end

            # Automatically confirm
            if automatic_confirmation
              booking.confirm!
            elsif SystemConfiguration::Variable.get_value('booking.assignation.automatic_resource_assignation_on_backoffice_request', 'false').to_bool
              booking.assign_available_stock  
            end             

            logger.debug "Created booking"
            # Remove the shopping_cart_renting_id from the session
            session.delete('back_office_shopping_cart_renting_id')
            # Prepare response
            content_type :json
            booking.to_json(only: [:id])
          else
            logger.error "Shopping cart does not exist"
            content_type 'json'
            status 404
            {error: 'Shopping cart not found'}.to_json
          end

        end


      end

    end # BookingNewReservationRESTApi
  end # YitoExtension
end # Sinatra