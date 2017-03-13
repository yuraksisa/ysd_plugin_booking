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

      	#
      	# Get the renting shopping cart
      	#
        app.route :get, ['/api/booking/frontend/shopping-cart',
                         '/api/booking/frontend/shopping-cart/:free_access_id'
                         ] do

          # Retrieve the shopping cart
          shopping_cart = if params[:free_access_id]
                            ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
                          elsif session.has_key?(:shopping_cart_renting_id)
                            ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
                          elsif params[:date_from] && params[:date_to]
                            date_from = params[:date_from]
                            time_from = params[:time_from]
                            date_to = params[:date_to]
                            time_to = params[:time_to]
                            pickup_place = params[:pickup_place]
                            return_place = params[:return_place]
                            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.create(
                                date_from: date_from, time_from: time_from,
                                date_to: date_to, time_to: time_to,
                                pickup_place: pickup_place, return_place: return_place)
                            session[:shopping_cart_renting_id] = shopping_cart.id
                          end

          # Return the shopping cart
          if shopping_cart
            content_type 'json'
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "No shopping cart"
            status 404
          end

      	end

        #
        # Set the renting product
        #
        app.route :post, ['/api/booking/frontend/shopping-cart/set-product',
                          '/api/booking/frontend/shopping-cart/:free_access_id/set-product'] do

          # Request data
          product_code = params[:product]

          # Retrieve the shopping cart
          shopping_cart = if params[:free_access_id]
                            ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
                          elsif session.has_key?(:shopping_cart_renting_id)
                            ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
                          end

          # Do the process
          if shopping_cart
            shopping_cart.set_item(product_code)
            content_type 'json'
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "No shopping cart"
            status 404
          end

        end

        #
        # Set an extra
        #
        app.route :post, ['/api/booking/frontend/shopping-cart/set-extra',
                          '/api/booking/frontend/shopping-cart/:free_access_id/set-extra'] do

          # Request data
          extra_code = params[:extra]
          extra_quantity = params[:quantity].to_i || 1

          # Retrieve the shopping cart
          shopping_cart = if params[:free_access_id]
                            ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
                          elsif session.has_key?(:shopping_cart_renting_id)
                            ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
                          end

          # Do the process
          if shopping_cart
            shopping_cart.set_extra(extra_code, extra_quantity)
            content_type :json
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "No shopping cart"
            status 404
          end

        end

        #
        # Remove extra
        #
        app.route :post, ['/api/booking/frontend/shopping-cart/remove-extra',
                          '/api/booking/frontend/shopping-cart/:free_access_id/remove-extra'] do

          # Request data
          extra_code = params[:extra]

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
            logger.error "No shopping cart"
            status 404
          end

        end

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
            # Updates the shopping cart
            pay_now = request_data['payment'] != 'none'
            payment_method_id = request_data['payment'] != 'none' ? request_data['payment'] : nil
            shopping_cart.update(customer_name: request_data['customer_name'],
                                 customer_surname: request_data['customer_surname'],
                                 customer_email: request_data['customer_email'],
                                 customer_phone: request_data['customer_phone'],
                                 customer_mobile_phone: request_data['customer_mobile_phone'],
                                 comments: request_data['comments'],
                                 pay_now: pay_now,
                                 payment_method_id: payment_method_id
            )
            logger.debug "Updated shopping cart"
            # Creates the booking
            booking = BookingDataSystem::Booking.create_from_shopping_cart(shopping_cart)
            logger.debug "Created booking"
            # Remove the shopping_cart_renting_id from the session
            session.delete(:shopping_cart_renting_id)
            # Add the booking_id to the session
            session[:booking_id] = booking.id
            # Prepare response
            content_type :json
            booking.to_json(only: [:free_access_id, :pay_now, :payment, :payment_method_id])
          else
            logger.error "No shopping cart"
            status 404
          end

        end

        #
        # Get the reservation
        #
        app.post '/api/booking/frontend/booking/:free_access_id' do

          booking = BookingDataSystem::Booking.get_by_free_access_id(params[:free_access_id])

          if booking
            content :json
            booking.to_json
          else
            logger.error "Booking not found #{params[:id]}"
            status 404
          end

        end

      end
    end
  end
end