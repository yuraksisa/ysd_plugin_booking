module Sinatra
  module YitoExtension
    module BookingDriverAgeRulesManagement

      def self.registered(app)

        #
        # Pickup/return places
        #
        app.get '/admin/booking/driver-age-rules/:driver_age_rule_definition_id?*', :allowed_usergroups => ['booking_manager','staff'] do
          if driver_age_rule_definition = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(params[:driver_age_rule_definition_id].to_i)
            locals = {:booking_driver_age_rules => 20,
                      :driver_age_rule_definition => driver_age_rule_definition}

            load_em_page :booking_driver_age_rules_management,
                         :driver_age_rule_definition, false, :locals => locals
          else
            status 404
          end

        end

      end

    end
  end
end