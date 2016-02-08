module Sinatra
  module YitoExtension
    module BookingCategoryManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking category
        #
        ["/api/booking-categories","/api/booking-categories/page/:page"].each do |path|
          
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
            
              total = conditions.build_datamapper(::Yito::Model::Booking::BookingCategory).all.count 
              data = conditions.build_datamapper(::Yito::Model::Booking::BookingCategory).all(offset_order_query) 

            else
              data,total  = ::Yito::Model::Booking::BookingCategory.all_and_count(offset_order_query)
            end

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
          
          begin
            booking_category = ::Yito::Model::Booking::BookingCategory.new(booking_category_request)
            booking_category.save
          rescue DataMapper::SaveFailureError => error
            p "Error saving booking category. #{booking_category.inspect} #{booking_category.errors.inspect}"
            raise error
          end  

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
                              
          if booking_category = ::Yito::Model::Booking::BookingCategory.get(booking_category_request.delete(:code))     
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
          key = booking_category_request.delete(:code)
          
          if booking_category = ::Yito::Model::Booking::BookingCategory.get(key)
            booking_category.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end