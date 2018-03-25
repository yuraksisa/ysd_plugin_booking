module Sinatra
  module YitoExtension
    module BookingPrereservationManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking prereservations planning
        #
        ["/api/booking-prereservations","/api/booking-prereservations/page/:page"].each do |path|
          
          app.post path do

            page = [params[:page].to_i, 1].max  
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:date_from.desc]}
            
            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))
              search_text = search_request['search']
              conditions = Conditions::Comparison.new(:title, '$like', "%#{search_text}%")

              total = conditions.build_datamapper(BookingDataSystem::BookingPrereservation).all.count
              data = conditions.build_datamapper(BookingDataSystem::BookingPrereservation).all(offset_order_query)
            else
              data,total  = BookingDataSystem::BookingPrereservation.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
    
        #
        # Get a booking prereservations planning
        #
        app.get "/api/booking-prereservation/:id" do
        
          data = BookingDataSystem::BookingPrereservation.get(params['id'])
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a new booking prereservations planning
        #
        #
        app.post "/api/booking-prereservation" do
        
          request_data = body_as_json(BookingDataSystem::BookingPrereservation)
          
          begin
            data = BookingDataSystem::BookingPrereservation.new(request_data)
            if booking_item = ::Yito::Model::Booking::BookingItem.get(data.booking_item_reference)
              data.booking_item_category = booking_item.category.code if booking_item.category
            end
            data.save
          rescue DataMapper::SaveFailureError => error
            p "Error saving booking prereservation. #{data.inspect} #{data.errors.inspect}"
            raise error
          end  

          # Return          
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a booking prereservations planning
        #
        app.put "/api/booking-prereservation" do
          
          data_request = body_as_json(BookingDataSystem::BookingPrereservation)

          if data = BookingDataSystem::BookingPrereservation.get(data_request.delete(:id))     
            begin
              data.attributes=(data_request)  
              if booking_item = ::Yito::Model::Booking::BookingItem.get(data.booking_item_reference)
                data.booking_item_category = booking_item.category.code if booking_item.category and booking_item.category.code != data.booking_item_category
              end              
              data.save
            rescue DataMapper::SaveFailureError => error
              p "Error updating booking prereservation. #{data.inspect} #{data.errors.inspect}"
              raise error
            end  
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes a booking prereservations planning
        #
        app.delete "/api/booking-prereservation" do
        
          data_request = body_as_json(BookingDataSystem::BookingPrereservation)
          
          # Remove the key
          key = data_request.delete(:id)
          
          if data = BookingDataSystem::BookingPrereservation.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end