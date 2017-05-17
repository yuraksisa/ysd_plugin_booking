module Sinatra
  module YitoExtension
    module BookingNewReservation

      def self.registered(app)

        #
        # Booking customers search
        #
        app.get '/admin/booking/customers/?*', :allowed_usergroups => ['booking_manager','booking_operator','staff'] do

          load_page(:booking_management_new_reservation_customer_selection)

        end

        #
        # Booking customers search
        #
        app.post '/admin/booking/customers/?*', :allowed_usergroups => ['booking_manager','booking_operator','staff'] do

          @item_count, @bookings = BookingDataSystem::Booking.customer_search(params[:search],{})
          
          load_page(:booking_management_new_reservation_customer_selection)

        end

        #
        # Create new booking
        #
        app.route :get, :post, ['/admin/booking/new/:booking_catalog_code',
                                '/admin/booking/new'], :allowed_usergroups => ['booking_manager','booking_operator','staff'] do

          locals = {}

          catalog = nil
          if params[:booking_catalog_code]
            catalog = ::Yito::Model::Booking::Catalog.get(params[:booking_catalog_code])
          end

          reservation_mode = catalog ? catalog.selector.to_sym : SystemConfiguration::Variable.get_value('booking.reservation_starts_with', :dates).to_sym
          product_family = catalog ? catalog.product_family : ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))

          locals.store(:booking_reservation_starts_with, reservation_mode)
          locals.store(:booking_item_family, product_family)
          locals.store(:booking_allow_custom_pickup_return_place,
                       SystemConfiguration::Variable.get_value('booking.allow_custom_pickup_return_place', 'false').to_bool)
          locals.store(:booking_custom_pickup_return_place_cost, BigDecimal.new(SystemConfiguration::Variable.get_value('booking.custom_pickup_return_place_price', '0')))

          pickup_return_place_def = nil
          pickup_return_place_def_id = SystemConfiguration::Variable.get_value('booking.pickup_return_place_definition','0').to_i
          if pickup_return_place_def_id > 0
            pickup_return_place_def = ::Yito::Model::Booking::PickupReturnPlaceDefinition.get(pickup_return_place_def_id)
          end
          pickup_return_place_def = ::Yito::Model::Booking::PickupReturnPlaceDefinition.first if pickup_return_place_def.nil?
          locals.store(:booking_pickup_return_places, pickup_return_place_def.pickup_return_places)

          locals.store(:booking_deposit,
                       SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i)
          locals.store(:booking_min_days,
                       SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i)



          @shopping_cart = nil

          if session.has_key?('back_office_shopping_cart_renting_id')
            @shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session['back_office_shopping_cart_renting_id'])
            @shopping_cart.clear
          end

          if @shopping_cart.nil?
            @shopping_cart =::Yito::Model::Booking::ShoppingCartRenting.new
          end

          if product_family.cycle_of_24_hours
            @shopping_cart.date_from = Date.today
            @shopping_cart.date_to = Date.today + 1
            @shopping_cart.time_from = "10:00"
            @shopping_cart.time_to = "10:00"
          else
            @shopping_cart.date_from = Date.today
            @shopping_cart.date_to = Date.today
            @shopping_cart.time_from = "10:00"
            @shopping_cart.time_to = "20:00"
          end

          if params[:customer_name] and params[:customer_surname] and
             params[:customer_phone] and params[:customer_email]
            if booking = BookingDataSystem::Booking.first_customer_booking(params)
              @shopping_cart.update_from_booking(booking)
            end
          end

          @shopping_cart.save
          session['back_office_shopping_cart_renting_id'] = @shopping_cart.id unless session.has_key?('back_office_shopping_cart_renting_id')

          load_page(:booking_management_new_reservation, :locals => locals)

        end

      end
    end
  end
end