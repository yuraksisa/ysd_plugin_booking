module Sinatra
  module YitoExtension
    module BookingFrontend

      def self.registered(app)

				# TODO CHECK VARIABLES if RESERVATION_MODE = 2.0

				app.set :bookingcharge_gateway_return_ok, '/reserva/payment-gateway-return/ok'
				app.set :bookingcharge_gateway_return_cancel, '/reserva/payment-gateway-return/cancel'
				app.set :bookingcharge_gateway_return_nok, '/reserva/payment-gateway-return/nok'

				# =================== RESERVATION PROCESS (FRONT-END) ==========================================

      	#
      	# Step 1 in reservation : choose product
      	#
      	app.route :get, :post, ['/reserva/producto', '/book/product'] do

      	  	# Retrive the parameters from the request
      	  	date_from = params[:date_from]
      	  	time_from = params[:time_from]
      	  	date_to = params[:date_to]
      	  	time_to = params[:time_to]
      	  	pickup_place = params[:pickup_place]
      	  	return_place = params[:return_place]

      	  	# Retrieve or create a new shopping cart
      	  	shopping_cart = nil
      	  	if session.has_key?(:shopping_cart_renting_id)
      	  	  if shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
      	  	    shopping_cart.update(date_from: date_from, time_from: time_from,
                                     date_to: date_to, time_to: time_to,
                                     pickup_place: pickup_place, return_place: return_place)
							end
						end
						if shopping_cart.nil?
      	  	  shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.create(
      	  	  					date_from: date_from, time_from: time_from,
      	  	  					date_to: date_to, time_to: time_to,
      	  	  					pickup_place: pickup_place, return_place: return_place)
      	  	  session[:shopping_cart_renting_id] = shopping_cart.id
      	  	end	

						# Prepare response
            locals = {}
            locals.store(:booking_min_days,
              SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i)
            locals.store(:booking_item_family, 
              ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))
            locals.store(:booking_item_type,
              SystemConfiguration::Variable.get_value('booking.item_type')) 
            locals.store(:booking_allow_custom_pickup_return_place,
              SystemConfiguration::Variable.get_value('booking.allow_custom_pickup_return_place', 'false').to_bool)

      	  	# Load the page
      	    load_page(:rent_reservation_choose_product, {page_title: 'Seleccionar producto', locals: locals})

        end

				#
				# Step 2 : Fill reservation form
				#
        ['/reserva/completar', '/book/complete'].each do |endpoint|
      	  app.get endpoint do

						locals = {}
						locals.store(:booking_item_family,
												 ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))
						locals.store(:booking_item_type,
												 SystemConfiguration::Variable.get_value('booking.item_type'))

      	  	load_page(:rent_reservation_complete, {page_title: 'Completar datos', locals: locals})

      	  end
      	end

				#
				# Step 3* : Payment [OPTIONAL]
				#
				['/reserva/pagar', '/book/pay'].each do |endpoint|
					app.post endpoint ,
									:allowed_origin => lambda { SystemConfiguration::Variable.get_value('site.domain') } do

						booking = BookingDataSystem::Booking.get_by_free_access_id(params[:id])
						if booking
							payment = params[:payment]
							payment_method = params[:payment_method_id]
							charge = booking.create_online_charge!(payment, payment_method)
							if charge
								session[:booking_id] = booking.id
								session[:charge_id] = charge.id
								status, header, body = call! env.merge("PATH_INFO" => "/charge",
																											 "REQUEST_METHOD" => 'GET')
							else
								status 404 # Charge not created
							end
						else
							status 404
						end

					end

      	end

				#
				# Step 4 : Reservation summary
				#
				['/reserva/:id', '/book/:id'].each do |endpoint|
					app.get endpoint do

						if @booking = BookingDataSystem::Booking.get_by_free_access_id(params[:id])
							load_page :rent_reservation_summary, {page_title: "Reserva #{@booking.id}"}
						else
							status 404
						end

					end

				end

				# =============== RETURN FROM PAYMENT GATEWAY ===================================

				#
				# Return OK from payment gateway
				#
				['/reserva/payment-gateway-return/ok'].each do |endpoint|
					app.get endpoint do

						if session.has_key?(:charge_id)
							@booking = BookingDataSystem::BookingCharge.booking_from_charge(session[:charge_id])
							load_page :rent_reservation_summary, {page_title: "Reserva #{@booking.id}"}
						else
							status 404
						end

					end
				end

				#
				# Return CANCEL from payment gateway
				#
				['/reserva/payment-gateway-return/cancel'].each do |endpoint|
					app.get endpoint do
						if session.has_key?(:charge_id)
							@booking = BookingDataSystem::BookingCharge.booking_from_charge(session[:charge_id])
							load_page :rent_reservation_summary, {page_title: "Reserva #{@booking.id}"}
						else
							status 404
						end
					end
				end

				#
				# Return NOK from payment gateway
				#
				['/reserva/payment-gateway-return/nok'].each do |endpoint|
					app.get endpoint do
						if session.has_key?(:charge_id)
							@booking = BookingDataSystem::BookingCharge.booking_from_charge(session[:charge_id])
							load_page :rent_reservation_summary, {page_title: "Reserva #{@booking.id}"}
						else
							status 404
						end
					end
				end

			end
    end
  end
end