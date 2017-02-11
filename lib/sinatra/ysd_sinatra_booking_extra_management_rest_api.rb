module Sinatra
  module YitoExtension
    module BookingExtraManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking-extra
        #
        ["/api/booking-extras","/api/booking-extras/page/:page"].each do |path|
          
          app.post path do

            page = [params[:page].to_i, 1].max  
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:code.asc]} 

            
            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))
              search_text = search_request['search']
              conditions = Conditions::JoinComparison.new('$or',
                                                          [Conditions::Comparison.new(:code, '$like', "%#{search_text}%"),
                                                           Conditions::Comparison.new(:name, '$like', "%#{search_text}%")
                                                          ])

              total = conditions.build_datamapper(::Yito::Model::Booking::BookingExtra).all.count 
              data = conditions.build_datamapper(::Yito::Model::Booking::BookingExtra).all(offset_order_query) 

            else            
              data,total  = ::Yito::Model::Booking::BookingExtra.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json

          
          end
        
        end
        
        #
        # Get booking-extra
        #
        app.get "/api/booking-extras" do

          data = if params[:all] and params[:all] == 'yes'
                   ::Yito::Model::Booking::BookingExtra.all(active: true)
                 else
                   ::Yito::Model::Booking::BookingExtra.all(active: true, web_public: true)
                 end

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