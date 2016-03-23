module Sinatra
  module YitoExtension
    module BookingActivityManagement

      def self.registered(app)
        
        #
        # Booking activities occupation
        #
        app.get '/admin/booking/activities-occupation', :allowed_usergroups => ['booking_manager','staff'] do

          today = Date.today
          
          @month = params[:month].to_i == 0 ? today.month : params[:month].to_i
          @year = params[:year].to_i == 0 ? today.year : params[:year].to_i

          @period = Date.civil(@year, @month)
          @next_period = @period >> 1
          @previous_period = @period << 1

          @days = Date.civil(@year, @month, -1).day
          @data = ::Yito::Model::Order::Order.cyclic_occupation_detail(@month, @year)
          
          load_page :booking_activity_occupation

        end

        #
        # Booking activities summary
        #
        app.get '/admin/booking/activities-summary/?', :allowed_usergroups => ['booking_manager','staff'] do 

          year = Date.today.year

          date_from = Date.civil(year,1,1)
          date_to = Date.civil(year,12,31)
          
          if params[:from]
            begin
              date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("activities summary from date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("activities summary from date not valid #{params[:to]}")
            end
          end

          @activities = ::Yito::Model::Order::Order.detail(date_from, date_to)

          load_page(:booking_activities_summary)

        end

        #
        # Booking activities
        #
        app.get '/admin/booking/activities/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          locals = {:booking_activity_page_size => 20}
          load_em_page :booking_activities_management, 
                       :activity, false, :locals => locals

        end        

      end

    end
  end
end
