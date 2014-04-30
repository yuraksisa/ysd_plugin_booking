module Sinatra
  module YitoExtension
    module BookingItemManagementRESTApi

      def self.registered(app)
        #                    
        # Query booking items
        #
        ["/api/booking-items","/api/booking-items/page/:page"].each do |path|
          
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
            
            data  = ::Yito::Model::Booking::BookingItem.all(:conditions => conditions, :limit => limit, :offset => offset)
            total = ::Yito::Model::Booking::BookingItem.count(conditions)
          
            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get a booking items
        #
        app.get "/api/booking-item/:id" do
        
          booking_item = ::Yito::Model::Booking::BookingItem.get(params['id'])
          
          status 200
          content_type :json
          booking_item.to_json
        
        end
        
        #
        # Get booking items
        #
        app.get "/api/booking-items" do

          booking_items = ::Yito::Model::Booking::BookingItem.all

          status 200
          content_type :json
          booking_items.to_json

        end

        #
        # Create a new booking item
        #
        #
        app.post "/api/booking-item" do
        
          booking_item_request = body_as_json(::Yito::Model::Booking::BookingItem)
          booking_item = ::Yito::Model::Booking::BookingItem.create(booking_item_request)

          # Return          
          status 200
          content_type :json
          booking_item.to_json          
        
        end
        
        #
        # Updates a content
        #
        app.put "/api/booking-item" do
          
          booking_item_request = body_as_json(::Yito::Model::Booking::BookingItem)
                              
          if booking_item = ::Yito::Model::Booking::BookingItem.get(content_request.delete(:id))     
            booking_item.attributes=(booking_item_request)  
            booking_item.save
          end
      
          content_type :json
          booking_item.to_json        
        
        end
        
        #
        # Deletes a content
        #
        app.delete "/api/booking-item" do
        
          booking_item_request = body_as_json(::Yito::Model::Booking::BookingItem)
          
          # Remove the content
          key = booking_item_request.delete(:reference)
          
          if booking_item = ::Yito::Model::Booking::BookingItem.get(key)
            content.delete
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end