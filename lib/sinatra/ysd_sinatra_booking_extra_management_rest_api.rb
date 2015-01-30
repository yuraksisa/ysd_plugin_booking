module Sinatra
  module YitoExtension
    module BookingExtraManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking-extra
        #
        ["/api/booking-extras","/api/booking-extras/page/:page"].each do |path|
          
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
            
            data  = ::Yito::Model::Booking::BookingExtra.all(:conditions => conditions, :limit => limit, :offset => offset)
            total = ::Yito::Model::Booking::BookingExtra.count(conditions)
          
            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get booking-extra
        #
        app.get "/api/booking-extras" do

          data = ::Yito::Model::Booking::BookingExtra.all()

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking-extra
        #
        app.get "/api/booking-extra/:id" do
        
          data = ::Yito::Model::Booking::BookingExtra.get(params[:code])
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a booking-extra
        #
        app.post "/api/booking-extra" do
        
          data_request = body_as_json(::Yito::Model::Booking::BookingExtra)
          data = ::Yito::Model::Booking::BookingExtra.create(data_request)
         
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a booking-extra
        #
        app.put "/api/booking-extra" do
          
          data_request = body_as_json(::Yito::Model::Booking::BookingExtra)
                              
          if data = ::Yito::Model::Booking::BookingExtra.get(data_request.delete(:code))     
            data.attributes=data_request  
            data.save
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes a booking-extra 
        #
        app.delete "/api/booking-extra" do
        
          data_request = body_as_json(::Yito::Model::Booking::BookingExtra)
          
          key = data_request.delete(:code)
          
          if data = ::Yito::Model::Booking::BookingExtra.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end