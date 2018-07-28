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

        #
        # Pickup/return places edition
        #
        app.get '/admin/booking/booking-driver-age-rules/:id', :allowed_usergroups => ['booking_manager', 'staff'] do

          if @driver_age_rules_definition = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(params[:id])
            load_page :booking_driver_age_rule_edition
          else
            status 404
          end

        end

      end

    end
  end
end