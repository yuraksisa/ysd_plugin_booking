module Sinatra
  module YSD
    #
    # Sinatra extension to configure booking plugin
    #
    module BookingConfiguration

      def self.registered(app)

        #
        # Booking configuration (general)
        #
        app.get '/admin/booking/config/general', :allowed_usergroups => ['booking_manager', 'staff'] do

          booking_renting, booking_activities = mybooking_plan
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],
                    :calendar_modes => {
                        :first_day =>  t.booking_settings.form.calendar_mode.first_day,
                        :default => t.booking_settings.form.calendar_mode.default
                    }}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          load_page(:config_booking_general, {:locals => locals})

        end

        #
        # Booking configuration (business)
        #
        app.get '/admin/booking/config/business', :allowed_usergroups => ['booking_manager', 'staff'] do

          booking_renting, booking_activities = mybooking_plan
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],
                    :calendar_modes => {
                        :first_day =>  t.booking_settings.form.calendar_mode.first_day,
                        :default => t.booking_settings.form.calendar_mode.default
                    }}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          load_page(:config_booking_business, {:locals => locals})

        end

        #
        # Booking configuration (reservations)
        #
        app.get '/admin/booking/config/reservations', :allowed_usergroups => ['booking_manager', 'staff'] do

          pickup_return_timetables = {"" => t.booking_settings.form.no_pickup_return_timetable}.merge(Hash[ *::Yito::Model::Calendar::Timetable.all.collect { |tt| [tt.id.to_s, tt.name] }.flatten])
          booking_renting, booking_activities = mybooking_plan
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          use_factors = SystemConfiguration::Variable.get_value('booking.use_factors_in_rates','false').to_bool
          locals = {:booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],
                    :calendar_modes => {
                        :first_day =>  t.booking_settings.form.calendar_mode.first_day,
                        :default => t.booking_settings.form.calendar_mode.default
                    },
                    :use_factors => use_factors,
                    :pickup_return_timetables => pickup_return_timetables}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          if booking_item_family and booking_item_family.driver
            locals.store(:booking_driver_age_rule_definition, SystemConfiguration::Variable.get_value('booking.driver_min_age.rule_definition'))
            locals.store(:booking_driver_age_rule_definitions, Hash[ *::Yito::Model::Booking::BookingDriverAgeRuleDefinition.all.collect { |v| [v.id.to_s, v.name]}.flatten])
          end
          load_page(:config_booking_reservations, {:locals => locals})

        end

        #
        # Booking configuration (back-office)
        #
        app.get '/admin/booking/config/backoffice', :allowed_usergroups => ['booking_manager', 'staff'] do

          booking_renting, booking_activities = mybooking_plan
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          multiple_locations = SystemConfiguration::Variable.get_value('booking.multiple_rental_locations', 'false').to_bool
          locals = {:booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],
                    :multiple_locations => multiple_locations}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)

          load_page(:config_booking_backoffice, {:locals => locals})

        end

        #
        # Booking configuration (payment)
        #
        app.get '/admin/booking/config/payment', :allowed_usergroups => ['booking_manager', 'staff'] do
          booking_renting, booking_activities = mybooking_plan
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          load_page(:config_booking_payment, {:locals => locals})
        end

        #
        # Booking configuration (notifications)
        #
        app.get '/admin/booking/config/notifications', :allowed_usergroups => ['booking_manager', 'staff'] do
          booking_renting, booking_activities = mybooking_plan
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          load_page(:config_booking_notifications, {:locals => locals})
        end

        #
        # Booking configuration (notifications) - renting customer messages templates
        #
        app.get '/admin/booking/config/notifications/renting-customer-templates', :allowed_usergroups => ['booking_manager', 'staff'] do
          if @show_translations = settings.multilanguage_site
            @tmpl_request = ContentManagerSystem::Template.first({:name => 'booking_customer_req_notification'})
            @tmpl_request_pay_now = ContentManagerSystem::Template.first({:name => 'booking_customer_req_pay_now_notification'})
            @tmpl_confirmation = ContentManagerSystem::Template.first({:name => 'booking_customer_notification'})
            @tmpl_payment_enabled = ContentManagerSystem::Template.first({:name => 'booking_customer_notification_payment_enabled'})
          end
          load_page(:config_booking_renting_notifications_customer_templates)
        end

        #
        # Booking configuration (notifications) - renting manager messages templates
        #
        app.get '/admin/booking/config/notifications/renting-manager-templates', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:config_booking_renting_notifications_manager_templates)
        end

        #
        # Booking configuration (notifications) - activities customer messages templates
        #
        app.get '/admin/booking/config/notifications/activities-customer-templates', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:config_booking_activities_notifications_customer_templates)
        end

        #
        # Booking configuration (notifications) - activities manager messages templates
        #
        app.get '/admin/booking/config/notifications/activities-manager-templates', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:config_booking_activities_notifications_manager_templates)
        end

        #
        # Booking configuration contract
        #
        app.get '/admin/booking/config/contract', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:config_booking_contract)
        end

        #
        # Booking configuration frontend
        #
        app.get '/admin/booking/config/front-end', :allowed_usergroups => ['booking_manager', 'staff'] do

          @logo = SystemConfiguration::Variable.get_value('site.logo',nil)
          @pages = ContentManagerSystem::Content.all(conditions: { type: 'page' },
                                                     order: [:title])
          @primary_links_menu = ::Site::Menu.first(name: 'primary_links')
          @secondary_links_menu = ::Site::Menu.first(name: 'secondary_links')

          load_page(:config_booking_frontend)
        end


      end
    end
  end
end