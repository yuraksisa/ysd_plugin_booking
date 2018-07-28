module Sinatra
  module YSD
    #
    # Sinatra Booking Extension : Occupation and availability
    #
    module BookingAvailabilityOccupation

      def self.registered(app)

        #
        # Booking monthly occupation
        # ---------------------------------------------------------------------------------------------------------
        #
        # == Query parameters::
        #
        # month::
        #   The month (current month if not used)
        # year::
        #   The year (current year if not used)
        # product::
        #   The category code
        # info::
        #   The presentation: 'percentage', 'values', 'rational'
        #
        app.get '/admin/booking/monthly-occupation', :allowed_usergroups => ['booking_manager','staff'] do

          today = Date.today

          @month = params[:month].to_i == 0 ? today.month : params[:month].to_i
          @year = params[:year].to_i == 0 ? today.year : params[:year].to_i
          @product = params[:product]
          @info = params[:info] || 'percentage'

          @period = Date.civil(@year, @month)
          @next_period = @period >> 1
          @previous_period = @period << 1

          @days = Date.civil(@year, @month, -1).day
          @data = BookingDataSystem::Booking.monthly_occupation(@month,
                                                                @year,
                                                                @product)

          load_page :booking_monthly_occupation

        end

        #
        # Booking renting products availability
        # ---------------------------------------------------------------------------------------------------------
        #
        # == Query parameters::
        #
        # from::
        #   The starting date (or today if not used)
        # to::
        #   The ending date (or the next week if not used)
        #
        app.get '/admin/booking/availability', :allowed_usergroups => ['booking_manager','staff'] do

          @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          @date_from = Date.today
          @date_to = Date.today + 7
          @time_from = @product_family.time_start
          @time_to = @product_family.time_end

          if params[:from]
            begin
              @date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("date not valid #{params[:from]}")
            end
          end

          if params[:time_from]
            begin
              DateTime.strptime(params[:time_from], '%H:%M')
              @time_from = params[:time_from]
            rescue
              logger.error("date not valid #{params[:time_from]}")
            end
          end

          if params[:to]
            begin
              @date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("date not valid #{params[:to]}")
            end
          end

          if params[:time_to]
            begin
              DateTime.strptime(params[:time_to], '%H:%M')
              @time_to = params[:time_to]
            rescue
              logger.error("time not valid #{params[:time_to]}")
            end
          end


          @data,@detail = BookingDataSystem::Booking.categories_availability(@date_from, @time_from, @date_to, @time_to)

          load_page :booking_availability

        end

        #
        # Booking renting extras availability
        # ------------------------------------------------------------------------------------------------------------
        #
        # == Query parameters::
        #
        # from::
        #   The starting date (or today if not used)
        # to::
        #   The ending date (or the next week if not used)
        #
        app.get '/admin/booking/extras-availability', :allowed_usergroups => ['booking_manager','staff'] do

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
          @data,@detail = BookingDataSystem::Booking.extras_resources_occupation(@date_from, @date_to)

          load_page :booking_extras_availability

        end

      end
    end
  end
end