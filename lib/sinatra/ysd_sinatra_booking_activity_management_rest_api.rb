module Sinatra
  module YitoExtension
    module BookingActivityManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking activity
        #
        ["/api/booking-activities","/api/booking-activities/page/:page"].each do |path|
          
          app.post path do

            page = [params[:page].to_i, 1].max  
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:code.asc]} 
            
            if request.media_type == "application/x-www-form-urlencoded"
              search_text = if params[:search]
                              params[:search]
                            else
                              request.body.rewind
                              request.body.read
                            end
              conditions = Conditions::Comparison.new(:code, '$eq', search_text)
            
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
        app.get "/api/booking-activities" do

          data = ::Yito::Model::Booking::Activity.all

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking activity
        #
        app.get "/api/booking-activity/:id" do
        
          data = ::Yito::Model::Booking::Activity.get(params['id'])
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a new booking activity
        #
        #
        app.post "/api/booking-activity" do
        
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
        app.put "/api/booking-activity" do
          
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
        app.delete "/api/booking-activity" do
        
          data_request = body_as_json(::Yito::Model::Booking::Activity)
          
          # Remove the key
          key = data_request.delete(:id)
          
          if data = ::Yito::Model::Booking::Activity.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end