module Sinatra
  module YSD

    module BookingActivitiesHelper

      def load_activity

          if session.has_key?(:activity_id)
            if session[:activity_id] != @activity.id
              session[:activity_id] = @activity.id
              session.delete(:activity_date_id)
              session.delete(:date)
              session.delete(:turn)
            end
          else
            session[:activity_id] = @activity.id
          end

          @occupation = {total_occupation: 0, occupation_detail: {}, occupation_capacity: @activity.capacity}
          
          if session[:activity_date_id]
            @activity_date_id = session[:activity_date_id]
            if @activity_date = ::Yito::Model::Booking::ActivityDate.get(@activity_date_id)
              @occupation = @activity.occupation(@activity_date.date_from, @activity_date.time_from)
            end
          elsif session[:date] or session[:turn]
            @date = session[:date] ? Date.strptime(session[:date],'%Y-%m-%d') : nil
            if session[:turn] && !session[:turn].to_s.empty?
              @time = session[:turn]
            else
              @time = nil
            end
            if @date and !@date.nil? and @time and !@time.nil?
              @occupation = @activity.occupation(@date, @time)
            end
          end

          # Load or build the shopping cart
          @shopping_cart = nil
            
          if session[:shopping_cart_id]
            @shopping_cart = ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
          end

          unless @shopping_cart
            @shopping_cart = ::Yito::Model::Order::ShoppingCart.new(:creation_date => DateTime.now)
          end       

          if @activity and @activity.active
            load_page(:reservation_activity, {cache: false})
          else
            status 404
          end
      end

    end 

    #
    # Sinatra extension to manage bookings
    #
    module BookingActivities

      def self.registered(app) 


        #
        # Show the programmed activities
        #
        ['/programmed-activities/?*','/actividades-programadas'].each do |endpoint|

          app.get endpoint do
            date = Date.today
            @activities = ::Yito::Model::Order::Order.public_programmed_activities(date)
            load_page(:reservation_programmed_activities)
          end

        end

      end

    end
  end
end
