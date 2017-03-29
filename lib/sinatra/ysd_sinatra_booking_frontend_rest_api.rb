module Sinatra
  module YitoExtension
    
    module BookingFrontendRESTApiHelper

      #
      # Build the shopping cart (with products and extras) to be served
      #
      def shopping_cart_to_json(shopping_cart)
      
        # Prepare the shopping cart
        only = [:free_access_id, :date_from, :time_from, :date_to, :time_to, :pickup_place, :return_place, :days,
                :item_cost, :extras_cost, :time_from_cost, :time_to_cost, :product_deposit_cost, :total_cost,
                :booking_amount, :pickup_place_cost, :return_place_cost,
                :customer_name, :customer_surname, :customer_email, :customer_phone, :customer_mobile_phone, :customer_document_id,
                :promotion_code, :comments ]
        relationships = {}
        relationships.store(:extras, {})
        relationships.store(:items, {:include => [:item_resources]})      

        sc_json = shopping_cart.to_json(only: only, relationships: relationships) 

        # Prepare the products
        p_json = ::Yito::Model::Booking::RentingSearch.search(shopping_cart.date_from,
                                            shopping_cart.date_to, shopping_cart.days).to_json

        # Prepare the extras
        e_json = ::Yito::Model::Booking::RentingExtraSearch.search(shopping_cart.date_from,
                                            shopping_cart.date_to, shopping_cart.days).to_json

        # Join all the data togheter
        "{\"shopping_cart\": #{sc_json}, \"products\": #{p_json}, \"extras\": #{e_json} }"


      end

      #
      # Build the booking (with products and extras) to be served
      #
      def booking_to_json(booking)

        # Prepare the booking
        b_json = booking.to_json

        # Prepare the products
        p_json = ::Yito::Model::Booking::RentingSearch.search(booking.date_from,
                                                              booking.date_to, booking.days).to_json

        # Prepare the extras
        e_json = ::Yito::Model::Booking::RentingExtraSearch.search(booking.date_from,
                                                                   booking.date_to, booking.days).to_json

        # Join all the data togheter
        "{\"booking\": #{b_json}, \"products\": #{p_json}, \"extras\": #{e_json} }"


      end

      #
      # Parses dd/mm/yyyy date
      #
      def parse_date(date_str)
        if /\d{2}\/\d{2}\/\d{4}/.match(date_str)
          return DateTime.strptime(date_str,'%d/%m/%Y')
        else
          return date_str
        end
      end

    end

    module BookingFrontendRESTApi

      def self.registered(app)

      	#
      	# Get the pickup places
      	#
      	app.get '/api/booking/frontend/pickup-places' do 

      	  BookingDataSystem.pickup_places.to_json(only: [:id, :name])

      	end

      	#
      	# Get the return places
      	#
      	app.get '/api/booking/frontend/return-places' do 

      	  BookingDataSystem.return_places.to_json(only: [:id, :name])

      	end

        #
        # Get the pickup /return time
        #
      	app.get '/api/booking/frontend/pickup-return-times' do 

		      BookingDataSystem.pickup_return_timetable.to_json

      	end

        # ------------------------------- Product ---------------------------------------------------

        #
        # Set/add the product
        #
        app.route :post, ['/api/booking/frontend/shopping-cart/set-product',
                          '/api/booking/frontend/shopping-cart/:free_access_id/set-product'] do

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
          if params[:free_access_id]
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
          elsif session.has_key?(:shopping_cart_renting_id)
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
          end

          # Do the process
          if shopping_cart
            shopping_cart.set_item(product_code, quantity)
            content_type 'json'
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "Shopping cart does not exist"
            halt 404, {error: 'Shopping cart not found'}.to_json
          end

        end

        # ------------------------------- Extras ---------------------------------------------------

        #
        # Set an extra
        #
        app.route :post, ['/api/booking/frontend/shopping-cart/set-extra',
                          '/api/booking/frontend/shopping-cart/:free_access_id/set-extra'] do

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
          shopping_cart = if params[:free_access_id]
                            ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
                          elsif session.has_key?(:shopping_cart_renting_id)
                            ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
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
        # Remove extra
        #
        app.route :post, ['/api/booking/frontend/shopping-cart/remove-extra',
                          '/api/booking/frontend/shopping-cart/:free_access_id/remove-extra'] do

          # Extract the data parameters
          begin
            request.body.rewind
            model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
          rescue JSON::ParserError
            halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
          end
          extra_code = model_request[:extra]

          # TODO : Validate it's a valid extra and it's contained in the shopping cart

          # Retrieve the shopping cart
          shopping_cart = if params[:free_access_id]
                            ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
                          elsif session.has_key?(:shopping_cart_renting_id)
                            ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
                          end

          # Do the process
          if shopping_cart
            shopping_cart.remove_extra(extra_code)
            content_type :json
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "Shopping cart does not exist"
            halt 404, {error: 'Shopping cart not found'}.to_json
          end

        end

        # ------------------------------- Checkout (confirm) ----------------------------------------------

        #
        # Confirm reservation
        #
        app.route :post, ['/api/booking/frontend/shopping-cart/checkout',
                          '/api/booking/frontend/shopping-cart/:free_access_id/checkout'] do

          # Request data
          request.body.rewind
          request_data = JSON.parse(URI.unescape(request.body.read))

          # Retrieve the shopping cart
          shopping_cart = if params[:free_access_id]
                            ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
                          elsif session.has_key?(:shopping_cart_renting_id)
                            ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
                          end

          # Do the process
          if shopping_cart
            # Basic data: customer, payment and comments
            shopping_cart.customer_name = request_data['customer_name'] || request_data['driver_name']
            shopping_cart.customer_surname = request_data['customer_surname'] || request_data['driver_surname']
            shopping_cart.customer_email = request_data['customer_email']
            shopping_cart.customer_phone = request_data['customer_phone']
            shopping_cart.customer_mobile_phone = request_data['customer_mobile_phone']
            shopping_cart.customer_document_id = request_data['customer_document_id'] || request_data['driver_document_id']
            shopping_cart.comments = request_data['comments']
            shopping_cart.pay_now =  (request_data['payment'] != 'none')
            shopping_cart.payment_method_id = (request_data['payment'] != 'none' ? request_data['payment'] : nil)
            # Number of adults/children (accomodation)
            shopping_cart.number_of_adults = request_data['number_of_adults'] if request_data.has_key?('number_of_adults')
            shopping_cart.number_of_children = request_data['number_of_children'] if request_data.has_key?('number_of_children')
            # Driver data (car/bike/truck renting)
            shopping_cart.driver_name = request_data['driver_name'] if request_data.has_key?('driver_name')
            shopping_cart.driver_surname = request_data['driver_surname']  if request_data.has_key?('driver_surname')
            shopping_cart.driver_document_id = request_data['driver_document_id'] if request_data.has_key?('driver_document_id')
            shopping_cart.driver_date_of_birth = parse_date(request_data['driver_date_of_birth'])  if request_data.has_key?('driver_date_of_birth')
            shopping_cart.driver_driving_license_number = request_data['driver_driving_license_number'] if request_data.has_key?('driver_driving_license_number')
            shopping_cart.driver_driving_license_date = parse_date(request_data['driver_driving_license_date']) if request_data.has_key?('driver_driving_license_date')
            shopping_cart.driver_driving_license_country = request_data['driver_driving_license_country'] if request_data.has_key?('driver_driving_license_country')
            if shopping_cart.driver_address.nil?
              shopping_cart.driver_address = LocationDataSystem::Address.new
            end
            shopping_cart.driver_address.street = request_data['street'] if request_data.has_key?('street')
            shopping_cart.driver_address.number = request_data['number']  if request_data.has_key?('number')
            shopping_cart.driver_address.complement = request_data['complement']  if request_data.has_key?('complement')
            shopping_cart.driver_address.city = request_data['city']  if request_data.has_key?('city')
            shopping_cart.driver_address.state = request_data['state']  if request_data.has_key?('state')
            shopping_cart.driver_address.country = request_data['country']  if request_data.has_key?('country')
            shopping_cart.driver_address.zip = request_data['zip']  if request_data.has_key?('zip')

            begin
              shopping_cart.save
            rescue DataMapper::SaveFailureError => error
              logger.error "Error saving shopping_cart #{error} #{shopping_cart.errors.full_messages.inspect}"
              halt 422, {error: shopping_cart.errors.full_messages}.to_json
            end

            logger.debug "Updated shopping cart"
            # Creates the booking
            booking = nil
            begin
              booking = BookingDataSystem::Booking.create_from_shopping_cart(shopping_cart)
              shopping_cart.destroy # Destroy the converted shopping cart
            rescue DataMapper::SaveFailureError => error
              logger.error "Error creating booking from shopping cart #{error.inspect}"
              logger.error "Error booking : #{booking.errors.full_messages.inspect}" if booking and booking.errors
              logger.error "Eroor shopping cart: #{shopping_cart.errors.full_message.inspect}" if shopping_cart and shopping_cart.errors
              halt 422, {error: booking.errors.full_messages}.to_json
            end
            logger.debug "Created booking"
            # Remove the shopping_cart_renting_id from the session
            session.delete(:shopping_cart_renting_id)
            # Add the booking_id to the session
            session[:booking_id] = booking.id
            # Prepare response
            content_type :json
            booking.to_json(only: [:free_access_id, :pay_now, :payment, :payment_method_id])
          else
            logger.error "Shopping cart does not exist"
            content_type 'json'
            status 404
            {error: 'Shopping cart not found'}.to_json
          end

        end

        # -------------------- Shopping cart -----------------------------------------

        #
        # Get the renting shopping cart
        #
        app.route :get, ['/api/booking/frontend/shopping-cart',
                         '/api/booking/frontend/shopping-cart/:free_access_id'] do

          shopping_cart = nil

          # Retrieve the shopping cart
          if params[:free_access_id]
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
          elsif session.has_key?(:shopping_cart_renting_id)
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
          end

          # Return the shopping cart
          if shopping_cart
            content_type 'json'
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "Shopping cart does not exist"
            content_type 'json'
            status 404
            {error: 'Shopping cart not found'}.to_json
          end

        end

        #
        # Create/Update the renting shopping cart
        #
        app.route :post, ['/api/booking/frontend/shopping-cart',
                          '/api/booking/frontend/shopping-cart/:free_access_id'] do

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
          date_from = time_from = date_to = time_to = pickup_place = return_place = nil
          if model_request[:date_from] && model_request[:date_to]
            date_from = DateTime.strptime(model_request[:date_from],"%d/%m/%Y")
            time_from = model_request[:time_from]
            date_to = DateTime.strptime(model_request[:date_to],"%d/%m/%Y")
            time_to = model_request[:time_to]
            pickup_place = model_request[:pickup_place]
            return_place = model_request[:return_place]
            number_of_adults = model_request[:number_of_adults]
            number_of_children = model_request[:number_of_children]
          else
            content_type :json
            status 422
            {error: 'Invalid request. data_from and date_to are required.'}.to_json
            halt
          end

          # Retrieve the shopping cart
          shopping_cart = nil
          if params[:free_access_id]
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
          elsif session.has_key?(:shopping_cart_renting_id)
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
          end

          # Updates or creates the shopping cart with the new dates or do create a new one if it does not exist
          if shopping_cart
            shopping_cart.change_selection_data(date_from, time_from,
                                                date_to, time_to,
                                                pickup_place, return_place,
                                                number_of_adults, number_of_children)
          else
            shopping_cart =::Yito::Model::Booking::ShoppingCartRenting.create(
                date_from: date_from, time_from: time_from,
                date_to: date_to, time_to: time_to,
                pickup_place: pickup_place, return_place: return_place,
                number_of_adults: number_of_adults, number_of_children: number_of_children)
            session[:shopping_cart_renting_id] = shopping_cart.id
          end

          # Return the shopping cart
          if shopping_cart
            content_type 'json'
            status 200
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "No shopping cart"
            content_type 'json'
            status 404
            {error: 'Shopping cart not found'}.to_json
          end

        end

        # ----------------------------- Reservation -----------------------------------------

        #
        # Get the reservation
        #
        app.get '/api/booking/frontend/booking/:free_access_id' do

          booking = BookingDataSystem::Booking.get_by_free_access_id(params[:free_access_id])

          if booking
            content_type 'json'
            booking_to_json(booking)
          else
            logger.error "Booking not found #{params[:id]}"
            content_type 'json'
            status 404
            {error: 'Booking not found'}.to_json
          end

        end

      end
    end
  end
end