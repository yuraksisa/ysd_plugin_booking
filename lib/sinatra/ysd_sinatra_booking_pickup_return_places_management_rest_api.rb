module Sinatra
  module YitoExtension
    module BookingPickupReturnPlacesManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking-places
        #
        ["/api/booking-places/:place_definition_id","/api/booking-places/:place_definition_id/page/:page"].each do |path|
          
          app.post path do

            page = params[:page].to_i || 1
            limit = settings.contents_page_size
            offset = (page-1) * settings.contents_page_size

            data  = ::Yito::Model::Booking::PickupReturnPlace.all(:place_definition_id => params[:place_definition_id], :limit => limit, :offset => offset)
            total = ::Yito::Model::Booking::PickupReturnPlace.count
          
            content_type :json
            {:data => data, :summary => {:total => total}}.to_json

          end
        
        end
        
        #
        # Get booking-place
        #
        app.get "/api/booking-places/:place_definition_id" do

          data = ::Yito::Model::Booking::PickupReturnPlace.all(:place_definition_id => params[:place_definition_id])

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking-place
        #
        app.get "/api/booking-place/:id" do
        
          data = ::Yito::Model::Booking::PickupReturnPlace.get(params[:id].to_i)
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a booking-place
        #
        app.post "/api/booking-place" do
        
          data_request = body_as_json(::Yito::Model::Booking::PickupReturnPlace)
          data = ::Yito::Model::Booking::PickupReturnPlace.create(data_request)
         
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a booking-place
        #
        app.put "/api/booking-place" do
          
          data_request = body_as_json(::Yito::Model::Booking::PickupReturnPlace)
                              
          if data = ::Yito::Model::Booking::PickupReturnPlace.get(data_request.delete(:id))     
            data.attributes=data_request  
            data.save
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes a booking-place 
        #
        app.delete "/api/booking-place" do
        
          data_request = body_as_json(::Yito::Model::Booking::PickupReturnPlace)
          
          key = data_request.delete(:id).to_i
          
          if data = ::Yito::Model::Booking::PickupReturnPlace.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end