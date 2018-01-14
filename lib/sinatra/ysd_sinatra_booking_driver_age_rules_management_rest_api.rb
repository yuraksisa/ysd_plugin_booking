module Sinatra
  module YitoExtension
    module BookingDriverAgeRulesManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking-driver-age-rules
        #
        ["/api/booking-driver-age-rules/:driver_age_rule_definition_id","/api/booking-driver-age-rules/:driver_age_rule_definition_id/page/:page"].each do |path|
          
          app.post path do

            page = params[:page].to_i || 1
            limit = 20
            offset = (page-1) * 20

            data  = ::Yito::Model::Booking::BookingDriverAgeRule.all(:driver_age_rule_definition_id => params[:driver_age_rule_definition_id], :limit => limit, :offset => offset)
            total = ::Yito::Model::Booking::BookingDriverAgeRule.count
          
            content_type :json
            {:data => data, :summary => {:total => total}}.to_json

          end
        
        end
        
        #
        # Get booking-driver-age-rule
        #
        app.get "/api/booking-driver-age-rule/:driver_age_rule_definition_id" do

          data = ::Yito::Model::Booking::BookingDriverAgeRule.all(:driver_age_rule_definition_id => params[:driver_age_rule_definition_id])

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking-driver-age-rule
        #
        app.get "/api/booking-driver-age-rule/:id" do
        
          data = ::Yito::Model::Booking::BookingDriverAgeRule.get(params[:id].to_i)
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a booking-driver-age-rule
        #
        app.post "/api/booking-driver-age-rule" do
        
          data_request = body_as_json(::Yito::Model::Booking::BookingDriverAgeRule)
          data = ::Yito::Model::Booking::BookingDriverAgeRule.create(data_request)
         
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a booking-driver-age-rule
        #
        app.put "/api/booking-driver-age-rule" do
          
          data_request = body_as_json(::Yito::Model::Booking::BookingDriverAgeRule)
                              
          if data = ::Yito::Model::Booking::BookingDriverAgeRule.get(data_request.delete(:id))
            data.attributes=data_request
            data.save
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes a booking-driver-age-rule
        #
        app.delete "/api/booking-driver-age-rule" do
        
          data_request = body_as_json(::Yito::Model::Booking::BookingDriverAgeRule)
          
          key = data_request.delete(:id).to_i
          
          if data = ::Yito::Model::Booking::BookingDriverAgeRule.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end