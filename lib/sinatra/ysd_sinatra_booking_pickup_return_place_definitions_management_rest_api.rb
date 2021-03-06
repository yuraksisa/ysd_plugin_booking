module Sinatra
  module YitoExtension
    module BookingPickupReturnPlaceDefinitionsManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking-place-def
        #
        ["/api/booking-place-defs","/api/booking-place-defs/page/:page"].each do |path|
          
          app.post path do

            page = [params[:page].to_i, 1].max
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:name.asc]}

            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))
              search_text = search_request['search']
              conditions = Conditions::Comparison.new(:name, '$like', "%#{search_text}%")

              total = conditions.build_datamapper(::Yito::Model::Booking::PickupReturnPlaceDefinition).all.count
              data = conditions.build_datamapper(::Yito::Model::Booking::PickupReturnPlaceDefinition).all(offset_order_query)
            else
              data,total  = ::Yito::Model::Booking::PickupReturnPlaceDefinition.all_and_count(offset_order_query)
            end

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

        # ---------------------------------------------------------------------------------------

        #
        # Append a pickup-return place
        #
        app.post '/api/booking-place-def/:id/pickup-return-place', allowed_usergroups: ['rates_manager','staff'] do

          if pickup_return_place_definition = ::Yito::Model::Booking::PickupReturnPlaceDefinition.get(params[:id])

            request_data = body_as_json(::Yito::Model::Booking::PickupReturnPlace)

            pickup_return_place = ::Yito::Model::Booking::PickupReturnPlace.new(request_data)
            pickup_return_place.pickup_return_place_definition = pickup_return_place_definition
            pickup_return_place.save

            pickup_return_place_definition.reload


            content_type :json
            {pickup_return_places: pickup_return_place_definition.pickup_return_places.to_a}.to_json

          else
            status 404
          end

        end

        #
        # Updates a pickup-return place
        #
        app.put '/api/booking-pickup-up-return-place/:id', allowed_usergroups: ['rates_manager','staff'] do

          if pickup_return_place = ::Yito::Model::Booking::PickupReturnPlace.get(params[:id])

            request_data = body_as_json(::Yito::Model::Booking::PickupReturnPlace)
            pickup_return_place.attributes = request_data
            pickup_return_place.save

            pickup_return_place_definition = pickup_return_place.pickup_return_place_definition
            pickup_return_place_definition.reload

            content_type :json
            {pickup_return_places: pickup_return_place_definition.pickup_return_places.to_a}.to_json

          else
            status 404
          end

        end

        #
        # Deletes pickup-return place
        #
        app.delete '/api/booking-pickup-up-return-place/:id', allowed_usergroups: ['rates_manager','staff'] do

          if pickup_return_place = ::Yito::Model::Booking::PickupReturnPlace.get(params[:id])

            pickup_return_place_definition = pickup_return_place.pickup_return_place_definition

            pickup_return_place.destroy

            pickup_return_place_definition.reload

            content_type :json
            {pickup_return_places: pickup_return_place_definition.pickup_return_places.to_a}.to_json

          else
            status 404
          end

        end

      end
    end
  end
end