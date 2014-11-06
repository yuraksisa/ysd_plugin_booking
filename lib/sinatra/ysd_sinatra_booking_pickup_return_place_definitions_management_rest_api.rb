module Sinatra
  module YitoExtension
    module BookingPickupReturnPlaceDefinitionsManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking-place-def
        #
        ["/api/booking-place-defs","/api/booking-place-defs/page/:page"].each do |path|
          
          app.post path do

            conditions = {}         
            
            if request.media_type == "application/x-www-form-urlencoded" # Just the text
              request.body.rewind
              search = JSON.parse(URI.unescape(request.body.read))
              if search.is_a?(Hash)
                search.each do |property, value| 
                end
              end
            end

            page = params[:page].to_i || 1
            limit = settings.contents_page_size
            offset = (page-1) * settings.contents_page_size
            
            data  = ::Yito::Model::Booking::PickupReturnPlaceDefinition.all(:conditions => conditions, :limit => limit, :offset => offset)
            total = ::Yito::Model::Booking::PickupReturnPlaceDefinition.count(conditions)
          
            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get booking-place-def
        #
        app.get "/api/booking-place-defs" do

          data = ::Yito::Model::Booking::PickupReturnPlaceDefinition.all()

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking-place-def
        #
        app.get "/api/booking-place-def/:id" do
        
          data = ::Yito::Model::Booking::PickupReturnPlaceDefinition.get(params[:id].to_i)
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a booking-place-def
        #
        app.post "/api/booking-place-def" do
        
          data_request = body_as_json(::Yito::Model::Booking::PickupReturnPlaceDefinition)
          data = ::Yito::Model::Booking::PickupReturnPlaceDefinition.create(data_request)
         
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a booking-place-def
        #
        app.put "/api/booking-place-def" do
          
          data_request = body_as_json(::Yito::Model::Booking::PickupReturnPlaceDefinition)
                              
          if data = ::Yito::Model::Booking::PickupReturnPlaceDefinition.get(data_request.delete(:id))     
            data.attributes=data_request  
            data.save
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes a booking-place-def 
        #
        app.delete "/api/booking-place-def" do
        
          data_request = body_as_json(::Yito::Model::Booking::PickupReturnPlaceDefinition)
          
          key = data_request.delete(:id).to_i
          
          if data = ::Yito::Model::Booking::PickupReturnPlaceDefinition.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end