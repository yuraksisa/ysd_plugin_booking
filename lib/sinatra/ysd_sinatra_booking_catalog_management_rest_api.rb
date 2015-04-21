module Sinatra
  module YitoExtension
    module BookingCatalogManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking-catalog
        #
        ["/api/booking-catalogs","/api/booking-catalogs/page/:page"].each do |path|
          
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
            
            data  = ::Yito::Model::Booking::BookingCatalog.all(:conditions => conditions, :limit => limit, :offset => offset)
            total = ::Yito::Model::Booking::BookingCatalog.count(conditions)
          
            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get booking-catalog
        #
        app.get "/api/booking-catalogs" do

          data = ::Yito::Model::Booking::BookingCatalog.all()

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking-catalog
        #
        app.get "/api/booking-catalog/:id" do
        
          data = ::Yito::Model::Booking::BookingCatalog.get(params[:code])
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a booking-catalog
        #
        app.post "/api/booking-catalog" do
        
          data_request = body_as_json(::Yito::Model::Booking::BookingCatalog)
          begin
            data = ::Yito::Model::Booking::BookingCatalog.new(data_request)
            data.save
          rescue DataMapper::SaveFailureError => error
            p "Error saving booking catalog. #{data.inspect}"
            raise error
          end  
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a booking-catalog
        #
        app.put "/api/booking-catalog" do
          
          data_request = body_as_json(::Yito::Model::Booking::BookingCatalog)
                              
          if data = ::Yito::Model::Booking::BookingCatalog.get(data_request.delete(:code))     
            data.attributes=data_request  
            data.save
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes a booking-catalog 
        #
        app.delete "/api/booking-catalog" do
        
          data_request = body_as_json(::Yito::Model::Booking::BookingCatalog)
          
          key = data_request.delete(:code)
          
          if data = ::Yito::Model::Booking::BookingCatalog.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end