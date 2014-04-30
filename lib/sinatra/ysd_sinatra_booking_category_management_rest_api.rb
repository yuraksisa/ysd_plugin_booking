module Sinatra
  module YitoExtension
    module BookingCategoryManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking category
        #
        ["/api/booking-categories","/api/booking-categories/page/:page"].each do |path|
          
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
            
            data  = ::Yito::Model::Booking::BookingCategory.all(:conditions => conditions, :limit => limit, :offset => offset)
            total = ::Yito::Model::Booking::BookingCategory.count(conditions)
          
            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get booking categories
        #
        app.get "/api/booking-categories" do

          booking_categories = ::Yito::Model::Booking::BookingCategory.all

          status 200
          content_type :json
          booking_categories.to_json

        end

        #
        # Get a booking category
        #
        app.get "/api/booking-category/:id" do
        
          booking_category = ::Yito::Model::Booking::BookingCategory.get(params['id'])
          
          status 200
          content_type :json
          booking_category.to_json
        
        end
        
        #
        # Create a new booking category
        #
        #
        app.post "/api/booking-category" do
        
          booking_category_request = body_as_json(::Yito::Model::Booking::BookingCategory)
          booking_category = ::Yito::Model::Booking::BookingCategory.create(booking_category_request)

          # Return          
          status 200
          content_type :json
          booking_category.to_json          
        
        end
        
        #
        # Updates a booking category
        #
        app.put "/api/booking-category" do
          
          booking_category_request = body_as_json(::Yito::Model::Booking::BookingCategory)
                              
          if booking_category = ::Yito::Model::Booking::BookingCategory.get(content_request.delete(:id))     
            booking_category.attributes=(booking_category_request)  
            booking_category.save
          end
      
          content_type :json
          booking_category.to_json        
        
        end
        
        #
        # Deletes a booking category
        #
        app.delete "/api/booking-category" do
        
          booking_category_request = body_as_json(::Yito::Model::Booking::BookingCategory)
          
          # Remove the content
          key = booking_category_request.delete(:reference)
          
          if booking_category = ::Yito::Model::Booking::BookingCategory.get(key)
            content.delete
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end