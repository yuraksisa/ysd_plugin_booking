module Sinatra
  module YitoExtension
    module BookingProductFamilyManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking-product-family
        #
        ["/api/booking-product-families","/api/booking-product-families/page/:page"].each do |path|
          
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
            limit = 20
            offset = (page-1) * 20
            
            data  = ::Yito::Model::Booking::ProductFamily.all(:conditions => conditions, :limit => limit, :offset => offset)
            total = ::Yito::Model::Booking::ProductFamily.count(conditions)
          
            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get booking-product-family
        #
        app.get "/api/booking-product-families" do

          data = ::Yito::Model::Booking::ProductFamily.all()

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking-product-family
        #
        app.get "/api/booking-product-family/:id" do
        
          data = ::Yito::Model::Booking::ProductFamily.get(params[:id])
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a booking-product-family
        #
        app.post "/api/booking-product-family" do
        
          data_request = body_as_json(::Yito::Model::Booking::ProductFamily)
          data = ::Yito::Model::Booking::ProductFamily.create(data_request)
         
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a booking-product-family
        #
        app.put "/api/booking-product-family" do
          
          data_request = body_as_json(::Yito::Model::Booking::ProductFamily)
                              
          if data = ::Yito::Model::Booking::ProductFamily.get(data_request.delete(:id))     
            data.attributes=data_request  
            data.save
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes a booking-product-family 
        #
        app.delete "/api/booking-product-family" do
        
          data_request = body_as_json(::Yito::Model::Booking::ProductFamily)
          
          key = data_request.delete(:id)
          
          if data = ::Yito::Model::Booking::ProductFamily.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end