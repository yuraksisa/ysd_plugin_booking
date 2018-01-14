module Sinatra
  module YitoExtension
    module BookingDriverAgeRuleDefinitionsManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking-driver-age-rule-definitions
        #
        ["/api/booking-driver-age-rule-definitions","/api/booking-driver-age-rule-definitions/page/:page"].each do |path|
          
          app.post path do

            page = [params[:page].to_i, 1].max
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:name.asc]}

            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))
              search_text = search_request['search']
              conditions = Conditions::Comparison.new(:name, '$like', "%#{search_text}%")

              total = conditions.build_datamapper(::Yito::Model::Booking::BookingDriverAgeRuleDefinition).all.count
              data = conditions.build_datamapper(::Yito::Model::Booking::BookingDriverAgeRuleDefinition).all(offset_order_query)
            else
              data,total  = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get all booking-driver-age-rule-definitions
        #
        app.get "/api/booking-driver-age-rule-definitions" do

          data = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.all()

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking-driver-age-rule-definition
        #
        app.get "/api/booking-driver-age-rule-definition/:id" do
        
          data = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(params[:id].to_i)
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a booking-driver-age-rule-definition
        #
        app.post "/api/booking-driver-age-rule-definition" do
        
          data_request = body_as_json(::Yito::Model::Booking::BookingDriverAgeRuleDefinition)
          data = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.create(data_request)
         
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a booking-driver-age-rule-definition
        #
        app.put "/api/booking-driver-age-rule-definition" do
          
          data_request = body_as_json(::Yito::Model::Booking::BookingDriverAgeRuleDefinition)
                              
          if data = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(data_request.delete(:id))
            data.attributes=data_request  
            data.save
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes a booking-driver-age-rule-definition
        #
        app.delete "/api/booking-driver-age-rule-definition" do
        
          data_request = body_as_json(::Yito::Model::Booking::BookingDriverAgeRuleDefinition)
          
          key = data_request.delete(:id).to_i
          
          if data = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end