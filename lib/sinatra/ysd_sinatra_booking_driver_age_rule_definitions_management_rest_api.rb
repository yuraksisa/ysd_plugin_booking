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

        # ---------------------------------------------------------------------------------------

        #
        # Append a driver age rule
        #
        app.post '/api/booking-driver-age-rule-definition/:id/driver-age-rule', allowed_usergroups: ['rates_manager','staff'] do

          if driver_age_rule_definition = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(params[:id])

            request_data = body_as_json(::Yito::Model::Booking::BookingDriverAgeRule)

            driver_age_rule = ::Yito::Model::Booking::BookingDriverAgeRule.new(request_data)
            driver_age_rule.driver_age_rule_definition = driver_age_rule_definition

            driver_age_rule.age_from = 0 if driver_age_rule.age_from.nil? or !driver_age_rule.age_from.is_a?Numeric
            driver_age_rule.age_to = 0 if driver_age_rule.age_to.nil? or !driver_age_rule.age_to.is_a?Numeric
            driver_age_rule.driving_license_years_from = 0 if driver_age_rule.driving_license_years_from.nil? or !driver_age_rule.driving_license_years_from.is_a?Numeric
            driver_age_rule.driving_license_years_to = 0 if driver_age_rule.driving_license_years_to.nil? or !driver_age_rule.driving_license_years_to.is_a?Numeric            
            
            #p "data: #{driver_age_rule.inspect} -- #{driver_age_rule.valid?} -- #{driver_age_rule.errors.inspect} -- #{driver_age_rule.errors.full_messages.inspect}"
            driver_age_rule.save

            driver_age_rule_definition.reload

            content_type :json
            {driver_age_rules: driver_age_rule_definition.driver_age_rules.to_a}.to_json

          else
            status 404
          end

        end

        #
        # Updates a driver age rule
        #
        app.put '/api/booking-driver-age-rule/:id', allowed_usergroups: ['rates_manager','staff'] do

          if driver_age_rule = ::Yito::Model::Booking::BookingDriverAgeRule.get(params[:id])

            request_data = body_as_json(::Yito::Model::Booking::BookingDriverAgeRule)
            driver_age_rule.attributes = request_data
            driver_age_rule.save

            driver_age_rule_definition = driver_age_rule.driver_age_rule_definition
            driver_age_rule_definition.reload

            content_type :json
            {driver_age_rules: driver_age_rule_definition.driver_age_rules.to_a}.to_json

          else
            status 404
          end

        end

        #
        # Deletes a driver age rule
        #
        app.delete '/api/booking-driver-age-rule/:id', allowed_usergroups: ['rates_manager','staff'] do

          if driver_age_rule = ::Yito::Model::Booking::BookingDriverAgeRule.get(params[:id])

            driver_age_rule_definition = driver_age_rule.driver_age_rule_definition

            driver_age_rule.destroy

            driver_age_rule_definition.reload

            content_type :json
            {driver_age_rules: driver_age_rule_definition.driver_age_rules.to_a}.to_json

          else
            status 404
          end

        end


      end
    end
  end
end