module Sinatra
  module YitoExtension
    module BookingDriverAgeRuleDefinitionsManagement

      def self.registered(app)

        #
        # Pickup/return places
        #
        app.get '/admin/booking/driver-age-rule-definitions/?*', :allowed_usergroups => ['booking_manager','staff'] do

          locals = {:booking_driver_age_rule_definitions => 20}
          load_em_page :booking_driver_age_rule_definitions_management,
                       :booking_driver_age_rule_definition, false, :locals => locals

        end

      end

    end
  end
end