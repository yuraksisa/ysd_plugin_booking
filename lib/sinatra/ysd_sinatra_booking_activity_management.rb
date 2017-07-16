module Sinatra
  module YitoExtension
    module BookingActivityManagement

      def self.registered(app)
        
        #
        # Booking activities occupation
        #
        app.get '/admin/booking/activities-occupation', :allowed_usergroups => ['booking_manager','booking_operator','staff'] do

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
        # Get the activities for a date
        #
        app.get '/admin/booking/day-activities/?', :allowed_usergroups => ['booking_manager','booking_operator','staff'] do

          @date = Date.today

          if params[:date]
            begin
              @date = DateTime.strptime(params[:date], '%Y-%m-%d')
            rescue
              logger.error("activities date not valid #{params[:date]}")
            end
          end

          @activities = ::Yito::Model::Order::Order.activities(@date)

          load_page(:booking_activities)

        end  

        #
        # Booking activities summary
        #
        app.get '/admin/booking/activities-summary/?', :allowed_usergroups => ['booking_manager','staff'] do 

          year = Date.today.year

          date_from = Date.today
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
              logger.error("activities summary to date not valid #{params[:to]}")
            end
          end

          @activities = ::Yito::Model::Order::Order.activities_summary(date_from, date_to)

          load_page(:booking_activities_summary)

        end

        #
        # Activity detail
        #
        app.get '/admin/booking/activity-detail/?*', :allowed_usergroups => ['booking_manager','booking_operator','staff'] do
 
          if params[:date] and params[:time] and params[:item_id]
            
            begin
              date = DateTime.strptime(params[:date], '%Y-%m-%d')
              @activities = ::Yito::Model::Order::Order.activity_detail(date, params[:time], params[:item_id])
              load_page(:booking_activity_detail)
            rescue Exception => e
              p "error: #{e.message}"
              status 500
            end

          else
            status 404
          end

        end

        #
        # Confirmed booking activities
        #
        app.get '/admin/booking/programmed-activities/?*', :allowed_usergroups => ['booking_manager','booking_operator','staff'] do

          year = Date.today.year

          date_from = Date.today
          date_to = Date.civil(year,12,31)
          
          if params[:from]
            begin
              date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("programmed activities from date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("programmed activities to date not valid #{params[:to]}")
            end
          end

          @activities = ::Yito::Model::Order::Order.programmed_activities_plus_pending(date_from, date_to)

          load_page(:booking_programmed_activities)

        end 

        #
        # Booking activities schedule
        #
        app.get '/admin/booking/activities-schedule/?*', :allowed_usergroups => ['booking_manager','booking_operator','staff'] do

          today = Date.today
          @year = today.year
          @month = today.month - 1

          load_page(:booking_activities_schedule)

        end  

        #
        # Pending of confirmation activities
        #
        app.get '/admin/booking/reports/pending-confirmation-activities', :allowed_usergroups => ['booking_manager', 'staff'] do
         
          @orders = ::Yito::Model::Order::Order.pending_of_confirmation
          load_page(:report_pending_confirmation_activities)

        end 


        #
        # Booking activities
        #
        app.get '/admin/booking/activities/?*', :allowed_usergroups => ['booking_manager','staff'] do

          # TODO multi-tenant
          @show_translations = settings.multilanguage_site
          locals = {:booking_activity_page_size => 20}
          load_em_page :booking_activities_management, 
                       :activity, false, :locals => locals

        end        

      end

    end
  end
end
