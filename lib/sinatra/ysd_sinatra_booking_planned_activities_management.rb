module Sinatra
  module YSD
    #
    # Sinatra extension to manage planned activities
    #
    module BookingPlannedActivitiesManagement

      def self.registered(app) 
        
        #
        # Get a planned activity information
        #
        app.get '/admin/booking/planned-activity/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          date = params[:date]
          time = params[:time]
          activity_code = params[:activity_code]
          @activity = ::Yito::Model::Booking::Activity.first(code: activity_code)

          if @planned_activity = ::Yito::Model::Booking::PlannedActivity.first(date: date, time: time, activity_code: activity_code)
            load_page(:planned_activity, :layout => false)
          else
          	@planned_activity = ::Yito::Model::Booking::PlannedActivity.new
          	@planned_activity.date = date
          	@planned_activity.time = time
          	@planned_activity.activity_code = activity_code
          	@planned_activity.capacity = @activity.capacity unless @activity.nil?
            load_page(:planned_activity, :layout => false)
          end

        end	

        #
        # Define a new planned activity
        #
        app.post '/admin/booking/planned-activity/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          @activity = ::Yito::Model::Booking::Activity.first(code: params[:activity_code])
          @planned_activity = ::Yito::Model::Booking::PlannedActivity.new
          @planned_activity.date = params[:date]
          @planned_activity.time = params[:time]
          @planned_activity.activity_code = params[:activity_code]
          @planned_activity.capacity = params[:capacity]
          @planned_activity.notes = params[:notes]
          begin
            @planned_activity.save
          rescue DataMapper::SaveFailureError => error
            p "Error creando planned_activity: #{@planned_activity.errors.inspect}"
            raise error
          end
          status 200

        end

        #
        # Update a planned activity
        #
        app.put '/admin/booking/planned-activity/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          date = params[:date]
          time = params[:time]
          activity_code = params[:activity_code]

          @activity = ::Yito::Model::Booking::Activity.first(code: params[:activity_code])

          if @planned_activity = ::Yito::Model::Booking::PlannedActivity.first(date: date, time: time, activity_code: activity_code)
            @planned_activity.capacity = params[:capacity] if params[:capacity]
            @planned_activity.notes = params[:notes] if params[:notes]
            begin
              @planned_activity.save
            rescue DataMapper::SaveFailureError => error
              p "Error actualizando planned_activity: #{@planned_activity.errors.inspect}"
              raise error
            end
            status 200
          else
          	p "not found"
            status 404
          end	

        end


      end

    end
  end
end  	