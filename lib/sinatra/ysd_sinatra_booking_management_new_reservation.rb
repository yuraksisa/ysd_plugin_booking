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
        # Show the page for creating a new booking
        #
        app.route :get, :post, ['/admin/booking/new/:booking_catalog_code',
                                '/admin/booking/new'], :allowed_usergroups => ['booking_manager','booking_operator','staff'] do

          locals = {}

          catalog = nil
          if params[:booking_catalog_code]
            catalog = ::Yito::Model::Booking::Catalog.get(params[:booking_catalog_code])
          end

          product_family = catalog ? catalog.product_family : ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          reservation_mode = product_family.frontend
          min_days = SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i
          
          locals.store(:booking_min_days, min_days)
          locals.store(:multiple_products, reservation_mode.to_sym == :shopcart)
          locals.store(:booking_item_family, product_family)
          locals.store(:pickup_return_places_configuration,
                       SystemConfiguration::Variable.get_value('booking.pickup_return_places_configuration', 'list'))
          locals.store(:booking_custom_pickup_return_place_cost, BigDecimal.new(SystemConfiguration::Variable.get_value('booking.custom_pickup_return_place_price', '0')))

          if product_family and product_family.pickup_return_place
            pickup_return_place_def = nil
            pickup_return_place_def_id = SystemConfiguration::Variable.get_value('booking.pickup_return_place_definition','0').to_i
            if pickup_return_place_def_id > 0
              pickup_return_place_def = ::Yito::Model::Booking::PickupReturnPlaceDefinition.get(pickup_return_place_def_id)
            end
            pickup_return_place_def = ::Yito::Model::Booking::PickupReturnPlaceDefinition.first if pickup_return_place_def.nil?
            locals.store(:booking_pickup_return_places, pickup_return_place_def.pickup_return_places)
          end

          if product_family and product_family.driver_license
            young_driver_rules = SystemConfiguration::Variable.get_value('booking.driver_min_age.rules', 'false').to_bool
            young_driver_rule_definition = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(SystemConfiguration::Variable.get_value('booking.driver_min_age.rule_definition'))
            locals.store(:driver_age_rules, young_driver_rules)
            locals.store(:driver_age_rule_definition, young_driver_rule_definition)
          else
            locals.store(:driver_age_rules, false)
          end

          @shopping_cart = nil

          if session.has_key?('back_office_shopping_cart_renting_id')
            @shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session['back_office_shopping_cart_renting_id'])
            @shopping_cart.clear unless @shopping_cart.nil?
          end

          if @shopping_cart.nil?
            @shopping_cart =::Yito::Model::Booking::ShoppingCartRenting.new
          end

          today = Date.today

          if product_family.cycle_of_24_hours
            @shopping_cart.date_from = today
            @shopping_cart.date_to = today + min_days
            @shopping_cart.time_from = product_family.time_start
            @shopping_cart.time_to = product_family.time_end
          else
            @shopping_cart.date_from = today
            @shopping_cart.date_to = today + min_days - 1
            @shopping_cart.time_from = product_family.time_start
            @shopping_cart.time_to = product_family.time_end
          end

          if params[:customer_name] and params[:customer_surname] and
             params[:customer_phone] and params[:customer_email]
            if booking = BookingDataSystem::Booking.first_customer_booking(params)
              @shopping_cart.update_from_booking(booking)
            end
          end

          @shopping_cart.save
          session['back_office_shopping_cart_renting_id'] = @shopping_cart.id unless session.has_key?('back_office_shopping_cart_renting_id')

          # Prepare sales channels
          addons = mybooking_addons
          @addon_sales_channels = (addons and addons.has_key?(:addon_sales_channels) and addons[:addon_sales_channels])
          if @addon_sales_channels
            @sales_channels = ::Yito::Model::SalesChannel::SalesChannel.all
          end
          
          load_page(:booking_management_new_reservation, :locals => locals)

        end

      end
    end
  end
end