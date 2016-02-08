module Sinatra
  module YSD
    #
    # Sinatra extension to manage bookings
    #
    module BookingActivities

      def self.registered(app) 
        
        #
        # Show the activities
        #
        app.get '/p/activities/?*' do 

          @activities = ::Yito::Model::Booking::Activity.all(active: true)
          load_page(:reservation_activities)

        end
        
        #
        # Show an activity
        #
        app.get '/p/activity/:id/?*' do

          @activity = ::Yito::Model::Booking::Activity.get(params[:id])
          
          if @activity and @activity.active
            load_page(:reservation_activity)
          else
          	status 404
          end

        end

      end

    end
  end
end
