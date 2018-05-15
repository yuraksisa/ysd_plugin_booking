module Sinatra
  module YitoExtension
    module BookingItemManagementRESTApi

      def self.registered(app)
        #                    
        # Query booking items
        #
        ["/api/booking-items","/api/booking-items/page/:page"].each do |path|
          
          app.post path, :allowed_usergroups => ['bookings_manager','staff'] do

            page = [params[:page].to_i, 1].max  
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:reference.asc]} 

            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))
              search_text = search_request['search']
              conditions = Conditions::JoinComparison.new('$or',
                                                          [Conditions::Comparison.new(:reference, '$like', "%#{search_text}%"),
                                                           Conditions::Comparison.new(:name, '$like', "%#{search_text}%")
                                                          ])
              if search_request['active'] == 'only'
                conditions = Conditions::JoinComparison.new('$and',
                                                          [conditions,
                                                          Conditions::Comparison.new(:active, '$eq', true)])
              end

              total = conditions.build_datamapper(::Yito::Model::Booking::BookingItem).all.count
              data = conditions.build_datamapper(::Yito::Model::Booking::BookingItem).all(offset_order_query)
            else
              data,total  = ::Yito::Model::Booking::BookingItem.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        app.get "/api/booking-items", :allowed_usergroups => ['bookings_manager','staff'] do

          booking_items = ::Yito::Model::Booking::BookingItem.all(:order => [:planning_order.asc, :category_code.asc, :reference.asc])

          status 200
          content_type :json
          booking_items.to_json

        end

        #
        # Get a booking items
        #
        app.get "/api/booking-item/:id", :allowed_usergroups => ['bookings_manager','staff'] do
        
          booking_item = ::Yito::Model::Booking::BookingItem.get(params['id'])
          
          status 200
          content_type :json
          booking_item.to_json
        
        end
        
        #
        # Create a new booking item
        #
        #
        app.post "/api/booking-item", :allowed_usergroups => ['bookings_manager','staff'] do
        
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
        app.put "/api/booking-item", :allowed_usergroups => ['bookings_manager','staff'] do
          
          booking_item_request = body_as_json(::Yito::Model::Booking::BookingItem)
                              
          if booking_item = ::Yito::Model::Booking::BookingItem.get(booking_item_request.delete(:reference))     
            booking_item.attributes=(booking_item_request)  
            booking_item.save
          end
      
          content_type :json
          booking_item.to_json        
        
        end

        #
        # Change a booking item reference and updates the resource
        #
        app.put "/api/booking-item/:reference/change", :allowed_usergroups => ['bookings_manager','staff'] do

          begin
            request.body.rewind
            model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
          rescue JSON::ParserError
            halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
          end

          if (booking_item = ::Yito::Model::Booking::BookingItem.get(params[:reference]))
            booking_item.transaction do
              booking_item.change_reference(model_request[:new_reference].strip)
            end
            booking_item = ::Yito::Model::Booking::BookingItem.get(model_request[:new_reference])
            content_type :json
            booking_item.to_json
          else
            halt 404 # Booking item reference not found
          end

        end
        
        #
        # Deletes a content
        #
        app.delete "/api/booking-item", :allowed_usergroups => ['bookings_manager','staff'] do
        
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