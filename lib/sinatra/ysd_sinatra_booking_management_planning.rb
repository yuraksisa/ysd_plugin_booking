module Sinatra
  module YSD
    #
    # Sinatra extension to manage booking planning
    #
    module BookingPlanning

      def self.registered(app)

        #
        # Bookings planning
        #
        app.get '/admin/booking/planning', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          today = Date.today

          @date_from = today

          if params[:mode] and ['stock','product'].include?(params[:mode])
            @mode = params[:mode].to_sym
          end

          if params[:product]
            @product = params[:product]
          end

          if params[:reference]
            @reference = params[:reference]
          end

          @assignation_allow_diferent_categories = SystemConfiguration::Variable.get_value('booking.assignation.allow_different_category', 'true').to_bool
          @assignation_allow_busy_resource = SystemConfiguration::Variable.get_value('booking.assignation.allow_busy_resource', 'true').to_bool
          @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          @pending_of_asignation_bookings = BookingDataSystem::Booking.pending_of_assignation
          @planning_style = SystemConfiguration::Variable.get_value('booking.assignation.planning_style','compact')

          # Prepare sales channels
          addons = mybooking_addons
          @addon_sales_channels = (addons and addons.has_key?(:addon_sales_channels) and addons[:addon_sales_channels])
          @sales_channels = ::Yito::Model::SalesChannel::SalesChannel.all if @addon_sales_channels
          @booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          @pickup_return_places_configuration = SystemConfiguration::Variable.get_value('booking.pickup_return_places_configuration', 'list')
          @driver_age_rules = SystemConfiguration::Variable.get_value('booking.driver_min_age.rules', 'false').to_bool
          @driver_age_rule_definition = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(SystemConfiguration::Variable.get_value('booking.driver_min_age.rule_definition'))
          if @product_family and @product_family.pickup_return_place and @pickup_place_def = ::Yito::Model::Booking::PickupReturnPlaceDefinition.first
            @pickup_places = ::Yito::Model::Booking::PickupReturnPlace.all(conditions: {place_definition_id: @pickup_place_def.id, is_pickup: true})
            @return_places = ::Yito::Model::Booking::PickupReturnPlace.all(conditions: {place_definition_id: @pickup_place_def.id, is_return: true})
          else
            @pickup_places = []
            @return_places = []
          end
          @min_days = SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i

          load_page(:bookings_planning)

        end

        #
        # Modify a reservation in the planning (only for multiple products setup)
        #
        app.get '/admin/booking/planning/modify-reservation/:id', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do


          if @booking = BookingDataSystem::Booking.get(params[:id])
            @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
            load_page(:booking_planning_modify_reservation)
          else
            status 404
          end

        end

        #
        # Planning : Change color
        #
        app.post '/admin/booking/planning-change-color', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do
          id = params[:id]
          type = params[:type]
          color = params[:color]

          if type == 'booking'
            if booking = BookingDataSystem::Booking.get(id)
              booking.planning_color = color
              booking.save
            else
              status 404
            end
          elsif type=="prereservation"
            if prereservation = BookingDataSystem::BookingPrereservation.get(id)
              prereservation.planning_color = color
              prereservation.save
            else
              status 404
            end
          else
            status 404
          end

        end

        #
        # (re)Assign reservation / prereservation
        #
        app.post '/admin/booking/planning-reassign-reservation', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          id = params[:id]
          resource = params[:resource]
          type = params[:type]

          if type == 'booking'
            if booking_line_resource = BookingDataSystem::BookingLineResource.get(id)
              if booking_item = ::Yito::Model::Booking::BookingItem.get(resource)
                  booking_line_resource.transaction do
                  booking_line_resource.booking_item_category = booking_item.category.code if booking_item.category
                  booking_line_resource.booking_item_reference = booking_item.reference
                  booking_line_resource.booking_item_stock_model = booking_item.stock_model
                  booking_line_resource.booking_item_stock_plate = booking_item.stock_plate
                  booking_line_resource.booking_item_characteristic_1 = booking_item.characteristic_1
                  booking_line_resource.booking_item_characteristic_2 = booking_item.characteristic_2
                  booking_line_resource.booking_item_characteristic_3 = booking_item.characteristic_3
                  booking_line_resource.booking_item_characteristic_4 = booking_item.characteristic_4
                  booking_line_resource.save
                  # Newsfeed
                  ::Yito::Model::Newsfeed::Newsfeed.create(category: 'booking',
                                                           action: 'assign_booking_resource',
                                                           identifier: booking_line_resource.booking_line.booking.id.to_s,
                                                           description: BookingDataSystem.r18n.t.booking_news_feed.assign_booking_resource(booking_line_resource.booking_item_reference,
                                                                                                                                           booking_line_resource.booking_line.id,
                                                                                                                                           booking_line_resource.booking_line.item_id),
                                                           attributes_updated: {category: booking_line_resource.booking_item_category,
                                                                                reference: booking_line_resource.booking_item_reference,
                                                                                stock_model: booking_line_resource.booking_item_stock_model,
                                                                                stock_plate: booking_line_resource.booking_item_stock_plate,
                                                                                characteristic_1: booking_line_resource.booking_item_characteristic_1,
                                                                                characteristic_2: booking_line_resource.booking_item_characteristic_2,
                                                                                characteristic_3: booking_line_resource.booking_item_characteristic_3,
                                                                                characteristic_4: booking_line_resource.booking_item_characteristic_4}.to_json)
                end
                status 200
              else
                status 404
              end
            else
              status 404
            end
          elsif type == 'prereservation'
            if prereservation = BookingDataSystem::BookingPrereservationLine.get(id)
              if booking_item = ::Yito::Model::Booking::BookingItem.get(resource)
                prereservation.booking_item_category = booking_item.category.code if booking_item.category
                prereservation.booking_item_reference = booking_item.reference
                prereservation.save
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


      end
    end
  end
end