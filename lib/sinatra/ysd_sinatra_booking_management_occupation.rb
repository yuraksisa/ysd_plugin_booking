module Sinatra
  module YSD
    #
    # Sinatra extension to manage bookings
    #
    module BookingOccupation

      def self.registered(app)

        #
        # Occupation detail (date and category)
        #
        app.get '/admin/booking/occupation-detail', :allowed_usergroups => ['booking_manager','staff'] do

          locals = {}
          if product_family_id = SystemConfiguration::Variable.get_value('booking.item_family')
            product_family = ::Yito::Model::Booking::ProductFamily.get(product_family_id)
            locals.store(:product_family, product_family)
            locals.store(:booking_reservation_starts_with, product_family.frontend)
          end

          @date = Date.today
          category = ::Yito::Model::Booking::BookingCategory.first
          @category_code = category ? category.code : nil

          if params[:date]
            begin
              @date = DateTime.strptime(params[:date], '%Y-%m-%d')
            rescue
              logger.error("date not valid #{params[:date]}")
            end
          end

          if params[:category]
            @category_code = params[:category]
          end

          options = {}
          if params[:layout]
            options.store(:layout, params[:layout])
          end
          options.store(:locals, locals)

          @reservations = BookingDataSystem::Booking.occupation_detail(@date, @category_code)

          @items = ::Yito::Model::Booking::BookingItem.all(category_code: @category_code).map { |item| item.reference }
          @reservation_items = @reservations.map { |r| r.booking_item_reference }
          @available_items = @items - @reservation_items


          load_page :occupation_detail, options

        end

        #
        # Get the product occupation for a month
        #
        app.get '/admin/booking/monthly-occupation', :allowed_usergroups => ['booking_manager','staff'] do

          today = Date.today

          @month = params[:month].to_i == 0 ? today.month : params[:month].to_i
          @year = params[:year].to_i == 0 ? today.year : params[:year].to_i
          @product = params[:product]

          @period = Date.civil(@year, @month)
          @next_period = @period >> 1
          @previous_period = @period << 1

          @days = Date.civil(@year, @month, -1).day
          @data = BookingDataSystem::Booking.monthly_occupation(@month,
                                                                @year,
                                                                @product)

          load_page :monthly_occupation

        end

        #
        # Check the resources occupation (AVAILABILITY)
        #
        app.get '/admin/booking/resources-occupation', :allowed_usergroups => ['booking_manager','staff'] do

          @date_from = Date.today
          @date_to = Date.today + 7

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

          @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          @data,@detail = BookingDataSystem::Booking.resources_occupation(@date_from, @date_to)

          load_page :resources_occupation

        end

      end
    end
  end
end