module Sinatra
  module YSD
    #
    # Sinatra extension to configure booking plugin
    #
    module BookingConfiguration

      def self.registered(app)

        #
        # Booking configuration (company)
        #
        app.get '/admin/booking/config/company', :allowed_usergroups => ['booking_manager', 'staff'] do

          booking_renting, booking_activities = mybooking_plan_type
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],
                    :calendar_modes => {
                        :first_day =>  t.booking_settings.basic.calendar_mode.first_day,
                        :default => t.booking_settings.basic.calendar_mode.default
                    }}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          load_page(:config_booking_company, {:locals => locals})

        end

        #
        # Booking configuration (basic)
        #
        app.get '/admin/booking/config/basic', :allowed_usergroups => ['booking_manager', 'staff'] do

          @addons = mybooking_addons

          booking_renting, booking_activities = mybooking_plan_type
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))

          locals = {:families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],
                    :calendar_modes => {
                        :first_day =>  t.booking_settings.basic.calendar_mode.first_day,
                        :default => t.booking_settings.basic.calendar_mode.default
                     },
                    :use_factors => SystemConfiguration::Variable.get_value('booking.use_factors_in_rates','false').to_bool,
                    :booking_item_family => booking_item_family,
                    :booking_renting => booking_renting,
                    :booking_activities => booking_activities
                    }

          if booking_item_family and booking_item_family.pickup_return_place
            locals.store(:booking_pickup_return_places_configuration, SystemConfiguration::Variable.get_value('booking.pickup_return_places_configuration', 'list'))
          end

          if booking_item_family and booking_item_family.driver
            @driver_age_rules_definition = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(SystemConfiguration::Variable.get_value('booking.driver_min_age.rule_definition'))
            locals.store(:booking_driver_age_rule_definition, SystemConfiguration::Variable.get_value('booking.driver_min_age.rule_definition'))
            locals.store(:booking_driver_age_rule_definitions, Hash[ *::Yito::Model::Booking::BookingDriverAgeRuleDefinition.all.collect { |v| [v.id.to_s, v.name]}.flatten])
          end

          if booking_item_family.time_to_from
            pickup_return_timetables = {"" => t.booking_settings.form.no_pickup_return_timetable}.merge(Hash[ *::Yito::Model::Calendar::Timetable.all.collect { |tt| [tt.id.to_s, tt.name] }.flatten])
            locals.store(:pickup_return_timetables, pickup_return_timetables)
            locals.store(:months, {'1': t.months.january, '2':t.months.february, '3':t.months.march, '4':t.months.april, '5':t.months.may,
                                   '6':t.months.june, '7':t.months.july, '8':t.months.august, '9':t.months.september, '10':t.months.october,
                                   '11':t.months.november, '12':t.months.december})
            locals.store(:days, %w{1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31})
            locals.store(:main_season_month_from, SystemConfiguration::Variable.get_value('booking.pickup_return_main_season.month_from', 1).to_i)
            locals.store(:main_season_day_from, SystemConfiguration::Variable.get_value('booking.pickup_return_main_season.day_from', 1).to_i)
            locals.store(:main_season_month_to, SystemConfiguration::Variable.get_value('booking.pickup_return_main_season.month_to', 12).to_i)
            locals.store(:main_season_day_to, SystemConfiguration::Variable.get_value('booking.pickup_return_main_season.day_to', 31).to_i)
            @timetable_id_season = SystemConfiguration::Variable.get_value('booking.pickup_return_timetable', nil)
            @timetable_id_out_season = SystemConfiguration::Variable.get_value('booking.pickup_return_timetable_out_of_season', nil)
          end

          @season_definition = booking_item_family.product_price_definition_season_definition
          @pickup_return_place_definition = ::Yito::Model::Booking::PickupReturnPlaceDefinition.get(SystemConfiguration::Variable.get_value('booking.pickup_return_place_definition').to_i)
          @show_translations = settings.multilanguage_site
          
          if @multiple_rental_locations = BookingDataSystem::Booking.multiple_rental_locations
            @rental_storages = ::Yito::Model::Booking::RentalStorage.all
            @rental_locations = ::Yito::Model::Booking::RentalLocation.all
          else
            @rental_storages = []
            @rental_locations = []  
          end  

          load_page(:config_booking_basic, {:locals => locals})

        end

        #
        # Booking configuration (advanced)
        #
        app.get '/admin/booking/config/advanced', :allowed_usergroups => ['booking_manager', 'staff'] do

          booking_renting, booking_activities = mybooking_plan_type
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],
                    :multiple_locations => BookingDataSystem::Booking.multiple_rental_locations}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)

          load_page(:config_booking_advanced, {:locals => locals})

        end

        #
        # Booking configuration (payment)
        #
        app.get '/admin/booking/config/payment', :allowed_usergroups => ['booking_manager', 'staff'] do
          booking_renting, booking_activities = mybooking_plan_type
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          load_page(:config_booking_payment, {:locals => locals})
        end

        #
        # Booking configuration (notifications)
        #
        app.get '/admin/booking/config/notifications', :allowed_usergroups => ['booking_manager', 'staff'] do
          booking_renting, booking_activities = mybooking_plan_type
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],}
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
          if @show_translations = settings.multilanguage_site
            @tmpl_request = ContentManagerSystem::Template.first({:name => 'order_customer_req_notification'})
            @tmpl_request_pay_now = ContentManagerSystem::Template.first({:name => 'order_customer_req_pay_now_notification'})
            @tmpl_confirmation = ContentManagerSystem::Template.first({:name => 'order_customer_notification'})
            @tmpl_payment_enabled = ContentManagerSystem::Template.first({:name => 'order_customer_notification_payment_enabled'})
          end
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

          @renting_plan, @activities_plan = mybooking_plan_type
          @addons = mybooking_addons
          
          @use_custom_contract = SystemConfiguration::Variable.get_value('booking.use_custom_contract', 'false').to_bool
          
          if @show_translations = settings.multilanguage_site
            @tmpl = ContentManagerSystem::Template.first({:name => 'booking_contract'}) if @renting_plan
            @tmpl_orders = ContentManagerSystem::Template.first({name: 'order_contract'}) if @activities_plan
          end

          load_page(:config_booking_contract)
        end

        #
        # Booking configuration (reservation web)
        #
        app.get '/admin/booking/config/frontend', :allowed_usergroups => ['booking_manager', 'staff'] do
          booking_renting, booking_activities = mybooking_plan_type
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],
                    :calendar_modes => {
                        :first_day =>  t.booking_settings.basic.calendar_mode.first_day,
                        :default => t.booking_settings.basic.calendar_mode.default
                    }}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          load_page(:config_booking_frontend, {:locals => locals})
        end

        #
        # Booking website structure and contents
        #
        app.get '/admin/booking/config/front-end-contents', :allowed_usergroups => ['booking_manager', 'staff'] do

          @renting_plan, @activities_plan = mybooking_plan_type

          @pages = ContentManagerSystem::Content.all(conditions: { type: 'page' },
                                                     order: [:title])
          @primary_links_menu = ::Site::Menu.first(name: 'primary_links')
          @secondary_links_menu = ::Site::Menu.first(name: 'secondary_links')

          if @renting_plan and @activities_plan
            if (@show_activities_menu = SystemConfiguration::Variable.get_value('booking.frontend.activities_menu','false').to_bool)
              @primary_links_activities_menu = ::Site::Menu.first(name: 'primary_links_activities')
              @secondary_links_activities_menu = ::Site::Menu.first(name: 'secondary_links_activities')
            end
          else
            @show_activities_menu = false
          end

          @translations = settings.multilanguage_site

          load_page(:config_booking_frontend_contents)
        end


      end
    end
  end
end