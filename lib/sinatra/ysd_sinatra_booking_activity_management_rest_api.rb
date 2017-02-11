module Sinatra
  module YitoExtension
    module BookingActivityManagementRESTApi

      def self.registered(app)

        #
        # Register a activity date
        #
        app.post '/api/booking-activities/date', :allowed_usergroups => ['bookings_manager','staff'] do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys! 

          if activity = ::Yito::Model::Booking::Activity.get(data[:id])
            activity.transaction do  
              activity_date = ::Yito::Model::Booking::ActivityDate.new
              activity_date.description = data[:description]
              activity_date.date_from = data[:date_from]
              activity_date.time_from = data[:time_from]
              activity_date.date_to = data[:date_to]
              activity_date.time_to = data[:time_to]
              activity_date.activity = activity
              activity_date.save
              activity.reload
            end
            content_type :json
            status 200
            activity.to_json
          else
            status 404
          end

        end

        #                    
        # Query booking activity
        #
        ["/api/booking-activities","/api/booking-activities/page/:page"].each do |path|
          
          app.post path, :allowed_usergroups => ['booking_manager', 'staff'] do
            page = [params[:page].to_i, 1].max  
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:code.asc]} 
            
            if request.media_type == "application/json"

              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))
              search_text = search_request['search']
              conditions = Conditions::JoinComparison.new('$or',
                                                          [Conditions::Comparison.new(:code, '$like', "%#{search_text}%"),
                                                           Conditions::Comparison.new(:name, '$like', "%#{search_text}%")
                                                          ])
              if search_request['active'] == 'only'
                conditions = Conditions::JoinComparison.new('$and',
                                                            [conditions,
                                                             Conditions::Comparison.new(:active, '$eq', true)])
              end

              total = conditions.build_datamapper(::Yito::Model::Booking::Activity).all.count
              data = conditions.build_datamapper(::Yito::Model::Booking::Activity).all(offset_order_query)


            else
              data,total  = ::Yito::Model::Booking::Activity.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get booking activities
        #
        app.get "/api/booking-activities", :allowed_usergroups => ['booking_manager', 'staff'] do

          data = if params[:all] and params[:all] == 'yes'
                   ::Yito::Model::Booking::Activity.all(active: true)
                 else
                   ::Yito::Model::Booking::Activity.all(active: true, web_public: true)
                 end

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking activity
        #
        app.get "/api/booking-activity/:id", :allowed_usergroups => ['booking_manager', 'staff'] do
        
          data = ::Yito::Model::Booking::Activity.get(params['id'])
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a new booking activity
        #
        #
        app.post "/api/booking-activity", :allowed_usergroups => ['booking_manager', 'staff'] do
        
          request_data = body_as_json(::Yito::Model::Booking::Activity)
          
          begin
            data = ::Yito::Model::Booking::Activity.new(request_data)
            data.save
          rescue DataMapper::SaveFailureError => error
            p "Error saving booking activity. #{data.inspect} #{data.errors.inspect}"
            raise error
          end  

          # Return          
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a booking activity
        #
        app.put "/api/booking-activity", :allowed_usergroups => ['booking_manager', 'staff'] do
          
          data_request = body_as_json(::Yito::Model::Booking::Activity)

          if data = ::Yito::Model::Booking::Activity.get(data_request.delete(:id))     
            begin
              data.attributes=(data_request)  
              data.save
            rescue DataMapper::SaveFailureError => error
              p "Error updating booking activity. #{data.inspect} #{data.errors.inspect}"
              raise error
            end  
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes a booking activity
        #
        app.delete "/api/booking-activity", :allowed_usergroups => ['booking_manager', 'staff'] do
        
          data_request = body_as_json(::Yito::Model::Booking::Activity)
          
          # Remove the key
          key = data_request.delete(:id)
          
          if data = ::Yito::Model::Booking::Activity.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

        #
        # Booking activities scheduler
        #
        app.get '/api/booking-activities/scheduler', :allowed_usergroups => ['booking_manager', 'staff'] do

          from = Time.at(params['start'].to_i)
          to = Time.at(params['end'].to_i)

          programmed_activities = ::Yito::Model::Order::Order.programmed_activities(from, to)

          booking_activities = programmed_activities.map do |item|
            time = item.time == 'TARDE' ? "19:00" : (item.time.size == 4 ? "0#{item.time}" : item.time)
            start_str = "#{item.date.strftime('%Y-%m-%d')}T#{time}:00"
            end_str = "#{item.date.strftime('%Y-%m-%d')}T#{time}:00"
            end_date = DateTime.parse(end_str)
            time = Time.parse(item.duration_hours)
            end_date += item.duration_days + (time.hour / 24.0) + (time.min / (24.0 * 60.0))  
            end_str = end_date.strftime('%Y-%m-%dT%H:%M:00')

            {:id => "#{item.item_id}-#{item.date.strftime('%Y-%m-%d')}-#{item.time}:00",
             :title => "#{item.item_description} (#{t.booking_activities_scheduler.pax("%.0f" % item.occupation)})",
             :start => start_str,
             :end => end_str,
             :allDay => item.duration_days > 0 ? true : false,
             :url => "/admin/booking/activity-detail?date=#{item.date.strftime('%Y-%m-%d')}&time=#{item.time}&item_id=#{item.item_id}",
             :editable => false,
             :backgroundColor => "#{item.schedule_color}",
             :textColor => 'black'}
          end

          booking_activities.to_json

        end
      end
    end
  end
end