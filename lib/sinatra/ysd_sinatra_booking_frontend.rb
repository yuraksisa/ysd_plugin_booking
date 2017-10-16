module Sinatra
  module YitoExtension
    module BookingFrontend

      def self.registered(app)

       if (defined?MY_BOOKING_FRONTEND) && (MY_BOOKING_FRONTEND == '4.0')
          p "Setting up mybooking 4.0"
		     app.set :bookingcharge_gateway_return_ok, '/reserva/payment-gateway-return/ok'
		     app.set :bookingcharge_gateway_return_cancel, '/reserva/payment-gateway-return/cancel'
		     app.set :bookingcharge_gateway_return_nok, '/reserva/payment-gateway-return/nok'
       end

		# =================== RESERVATION PROCESS (FRONT-END) ==========================================

      	#
      	# Step 1 in reservation : choose product
      	#
      	app.route :get, :post, ['/reserva/producto', '/book/product'] do

      	  	# Retrive the parameters from the request
					  booking_parameters = false
					  if params[:date_from] && params[:date_to]
      	  	  date_from = DateTime .strptime(params[:date_from],"%d/%m/%Y")
      	  	  time_from = params[:time_from]
      	  	  date_to = DateTime.strptime(params[:date_to],"%d/%m/%Y")
      	  	  time_to = params[:time_to]
      	  	  pickup_place = params[:pickup_place]
      	  	  return_place = params[:return_place]
							number_of_adults = params[:number_of_adults]
							number_of_children = params[:number_of_children]
							driver_age_rule_id = params[:driver_age_rule]
							booking_parameters = true
						end

      	  	# Retrieve or create a new shopping cart
      	  	@shopping_cart = nil

						if session.has_key?(:shopping_cart_renting_id)
      	  	  @shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
						end

						if @shopping_cart.nil?
							if booking_parameters
      	  	    @shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.create(
      	  	  					date_from: date_from, time_from: time_from,
      	  	  					date_to: date_to, time_to: time_to,
      	  	  					pickup_place: pickup_place, return_place: return_place,
								        number_of_adults: number_of_adults, number_of_children: number_of_children,
												driver_age_rule_id: driver_age_rule_id)
							else
								# TODO create default values or redirect home?
							end
      	  	  session[:shopping_cart_renting_id] = @shopping_cart.id
						else
							if booking_parameters
								@shopping_cart.change_selection_data(
										date_from, time_from,
										date_to, time_to,
										pickup_place, return_place,
										number_of_adults, number_of_children,
										driver_age_rule_id)
							end
						end

						# Prepare response
						booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
            locals = {}
            locals.store(:booking_min_days,
              SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i)
            locals.store(:booking_item_family, booking_item_family)
            locals.store(:booking_item_type,
              SystemConfiguration::Variable.get_value('booking.item_type')) 
            locals.store(:booking_allow_custom_pickup_return_place,
              SystemConfiguration::Variable.get_value('booking.allow_custom_pickup_return_place', 'false').to_bool)
						locals.store(:booking_driver_min_age_rules,
						  SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)

      	  	# Load the page
						title = booking_item_family.multiple_items? ? t.front_end_reservation.choose_products_page_title : t.front_end_reservation.choose_product_page_title
      	    load_page(:rent_reservation_choose_product, {page_title: title, locals: locals})

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
						locals.store(:total_cost_includes_deposit,
												 SystemConfiguration::Variable.get_value('booking.total_cost_includes_deposit', 'false').to_bool)
						locals.store(:booking_driver_min_age_rules,
												 SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)

      	  	load_page(:rent_reservation_complete, {page_title: t.front_end_reservation.complete_reservation_page_title , locals: locals})

      	  end
      	end

				#
				# Step 3* : Payment [OPTIONAL]
				#
				['/reserva/pagar', '/book/pay'].each do |endpoint|
					app.post endpoint do #, :allowed_origin => lambda { SystemConfiguration::Variable.get_value('site.domain') } do

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
							locals = {}
							locals.store(:total_cost_includes_deposit,
													 SystemConfiguration::Variable.get_value('booking.total_cost_includes_deposit', 'false').to_bool)
							locals.store(:booking_driver_min_age_rules,
													 SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)
							load_page :rent_reservation_summary, {page_title: t.front_end_reservation.summary_page_title(@booking.id), locals: locals}
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
							locals = {}
							locals.store(:total_cost_includes_deposit,
													 SystemConfiguration::Variable.get_value('booking.total_cost_includes_deposit', 'false').to_bool)
							locals.store(:booking_driver_min_age_rules,
													 SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)
							load_page :rent_reservation_summary, {page_title: t.front_end_reservation.summary_page_title(@booking.id), locals: locals}
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
							locals = {}
							locals.store(:total_cost_includes_deposit,
													 SystemConfiguration::Variable.get_value('booking.total_cost_includes_deposit', 'false').to_bool)
							locals.store(:booking_driver_min_age_rules,
													 SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)
							load_page :rent_reservation_summary, {page_title: t.front_end_reservation.summary_page_title(@booking.id), locals: locals}
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
							locals = {}
							locals.store(:total_cost_includes_deposit,
													 SystemConfiguration::Variable.get_value('booking.total_cost_includes_deposit', 'false').to_bool)
							locals.store(:booking_driver_min_age_rules,
													 SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)
							load_page :rent_reservation_summary, {page_title: t.front_end_reservation.summary_page_title(@booking.id), locals: locals}
						else
							status 404
						end
					end
				end

			end
    end
  end
end