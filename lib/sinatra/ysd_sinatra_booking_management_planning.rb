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
          #@pending_of_asignation_bookings = BookingDataSystem::Booking.pending_of_assignation
          
          load_page(:bookings_planning_v2)

        end

        #
        # Planning: Remove prereservation
        #
        app.post '/admin/booking/planning-remove-prereservation', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          id = params[:id]
          if prereservation = BookingDataSystem::BookingPrereservation.get(id)
            prereservation.destroy
            status 200
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
            if prereservation = BookingDataSystem::BookingPrereservation.get(id)
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

        #
        # The user select the reservations not asigned
        #
        #app.get '/admin/booking/planning-pending-assignation', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do
        #
        #  @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
        #
        #  @bookings = BookingDataSystem::Booking.pending_of_assignation
        #  load_page(:booking_planning_pending_assignation, :layout => false)
        #
        #end


      end
    end
  end
end