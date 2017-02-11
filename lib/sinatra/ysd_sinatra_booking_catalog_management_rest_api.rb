module Sinatra
  module YitoExtension
    module BookingCatalogManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking-catalog
        #
        ["/api/booking-catalogs","/api/booking-catalogs/page/:page"].each do |path|
          
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
                                                           Conditions::Comparison.new(:description, '$like', "%#{search_text}%")
                                                          ])

              total = conditions.build_datamapper(::Yito::Model::Booking::BookingCatalog).all.count
              data = conditions.build_datamapper(::Yito::Model::Booking::BookingCatalog).all(offset_order_query)

            else
              data,total  = ::Yito::Model::Booking::BookingCatalog.all_and_count(offset_order_query)
            end

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