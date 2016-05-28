module Sinatra
  module YitoExtension
    module BookingItemManagementRESTApi

      def self.registered(app)
        #                    
        # Query booking items
        #
        ["/api/booking-items","/api/booking-items/page/:page"].each do |path|
          
          app.post path do

            page = [params[:page].to_i, 1].max  
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:reference.asc]} 
            
            if request.media_type == "application/x-www-form-urlencoded"
              search_text = if params[:search]
                              params[:search]
                            else
                              request.body.rewind
                              request.body.read
                            end
              conditions = Conditions::JoinComparison.new('$or', 
                              [Conditions::Comparison.new(:reference, '$like', "%#{search_text}%"),
                               Conditions::Comparison.new(:name, '$like', "%#{search_text}%")
                              ])
            
              total = conditions.build_datamapper(::Yito::Model::Booking::BookingItem).all.count 
              data = conditions.build_datamapper(::Yito::Model::Booking::BookingItem).all(offset_order_query) 

            else
              data,total  = ::Yito::Model::Booking::BookingItem.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        app.get "/api/booking-items" do

          booking_items = ::Yito::Model::Booking::BookingItem.all(:order => [:planning_order.asc, :category_code.asc, :reference.asc])

          status 200
          content_type :json
          booking_items.to_json

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
                              
          if booking_item = ::Yito::Model::Booking::BookingItem.get(booking_item_request.delete(:reference))     
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
            booking_item.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end