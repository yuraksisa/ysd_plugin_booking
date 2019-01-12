require 'ysd-plugins_viewlistener' unless defined?Plugins::ViewListener
require 'ysd_md_configuration' unless defined?SystemConfiguration::Variable
require 'ysd_md_cms' unless defined?ContentManagerSystem::Template
require 'ysd_md_booking' unless defined?Yito::Model::Booking::ProductFamily

#
# Huasi CMS Extension
#
module Huasi
  class BookingExtension < Plugins::ViewListener

    # ========= Initialization ===========
    
    #
    # Extension initialization (on runtime)
    #
    def init(context={})

      app = context[:app]
      
      # View models
      ::Model::ViewModel.new(:activity, 
                             'activity', 
                             ::Yito::Model::Booking::Activity, 
                             :view_template_activities,
                             [])

    end

    # ========= Installation =================

    # 
    # Install the plugin
    #
    def install(context={})

      # Business configuration

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.item_family'},
          {:value => 'place',
           :description => 'Booking family: place or other',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.item_type'},
          {:value => 'apartment',
           :description => 'Booking Type : car, apartment, bike, motorbike, room',
           :module => :booking})


      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.automatic_confirm_web_reservation_request'},
          {:value => 'false',
           :description => 'Automatically confirm web reservation request',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.automatic_confirm_backoffice_reservation_request'},
          {:value => 'false',
           :description => 'Automatically confirm backoffice reservation request',
           :module => :booking})

      # Planning

      SystemConfiguration::Variable.first_or_create(
          {name: 'booking.reports.pickup_return'},
          {value: 'v1',
           description: 'Show the pickup/return report version',
           module: :booking}
      )

      SystemConfiguration::Variable.first_or_create(
          {name: 'booking.assignation.automatic_resource_assignation_on_web_request'},
          {value: 'true',
           description: 'It assigns automatically an available item on web reservation request',
           module: :booking}
      )

      SystemConfiguration::Variable.first_or_create(
          {name: 'booking.assignation.automatic_resource_assignation_on_backoffice_request'},
          {value: 'true',
           description: 'It assigns automatically an available item on backoffice reservation request',
           module: :booking}
      )      

      SystemConfiguration::Variable.first_or_create(
          {name: 'booking.assignation.automatic_resource_assignation'},
          {value: 'true',
           description: 'It assigns automatically an available item on confirm the reservation',
           module: :booking}
      )

      SystemConfiguration::Variable.first_or_create(
          {name: 'booking.assignation.allow_different_category'},
          {value: 'true',
           description: 'It allows to assign a different category resource to a reservation',
           module: :booking}
      )

      SystemConfiguration::Variable.first_or_create(
          {name: 'booking.assignation.allow_busy_resource'},
          {value: 'true',
           description: 'It allows to assign a busy resource to a reservation',
           module: :booking}
      )

      SystemConfiguration::Variable.first_or_create(
          {name: 'booking.assignation.planning_style'},
          {value: 'compact',
           description: 'Planning style: compact or extended',
           module: :booking}
      )

      SystemConfiguration::Variable.first_or_create(
                                       {name: 'booking.assignation.planning_full_day'},
                                       {value: 'false',
                                       description: 'Planning full day: show the planning as if was not 24hours cycle',
                                       module: :booking}
      )

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.assignation_hours_return_pickup'},
          {:value => '2',
           :description => 'Planning : Assignation hours between return - pickup',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {name: 'booking.assignation.automatically_manage_pending_of_confirmation'},
          {value: 'true',
           description: 'Manage automatically pending of confirmation reservations. If true, the system take them into account in order to control availability and planning pre-assignation',
           module: :booking}
      )

      # Online payment ------------------------------------------------------------------------------------------------

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.payment'},
          {:value => 'false',
           :description => 'Integrate the payment in the booking process. Values: true, false',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create({name: 'booking.payment_amount_setup'},
                                                    {value: 'deposit',
                                                     description: 'deposit, total or deposit_and_total ',
                                                     module: :booking}
      )

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.deposit'},
          {:value => '40',
           :description => 'Deposit percentage or 0 if no deposit management',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create({name: 'booking.allow_pending_payment'},
                  {value: 'true',
                  description: 'Allow to pay the pending amount (after the deposit payment)',
                  module: :booking})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.payment_cadence'},
        {:value => '48',
         :description => 'Cadence in hours from the reservation date to today',
         :module => :booking})

      # Reservation settings ------------------------------------------------------------------------------------------

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.item_hold_time'},
        {:value => '72',
         :description => 'Reservation expiration time',
         :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.hours_cadence'},
          {:value => '2',
           :description => 'Cadence in hours to apply one more day',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.min_days'},
        {:value => '1',
         :description => 'Minimum number of days you must book',
         :module => :booking})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.default_booking_catalog.code'},
        {:value => '',
         :description => 'Default booking catalog',
         :module => 'booking'})

      # Pickup/return places ------------------------------------------------------------------------------------------

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.pickup_return_places_configuration'},
          {:value => 'list',
           :description => 'pickup and return place: list - value - list+custom'})

      pickup_return_place_variable = SystemConfiguration::Variable.get('booking.pickup_return_place_definition')
      if pickup_return_place_variable.nil?
        pickup_return_place_definition = ::Yito::Model::Booking::PickupReturnPlaceDefinition.first_or_create({name: 'booking.pickup_return_place_definition'})
        SystemConfiguration::Variable.first_or_create(
            {:name => 'booking.pickup_return_place_definition'},
            {:value => pickup_return_place_definition.id.to_s,
             :description => 'Pickup and return place definition'})
      elsif pickup_return_place_variable.value == ''
        pickup_return_place_definition = ::Yito::Model::Booking::PickupReturnPlaceDefinition.first_or_create({name: 'booking.pickup_return_place_definition'})
        SystemConfiguration::Variable.set_value('booking.pickup_return_place_definition', pickup_return_place_definition.id.to_s)
      end

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.custom_pickup_return_place_price'},
        {:value => '0',
         :description => 'Custom pickup and return places cost'})

      # Pickup/return timetable ---------------------------------------------------------------------------------------

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.pickup_return_main_season.month_from'},
          {:value => '1',
           :description => 'Pickup and return places main season month from'})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.pickup_return_main_season.day_from'},
          {:value => '1',
           :description => 'Pickup and return places main season day from'})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.pickup_return_main_season.month_to'},
          {:value => '12',
           :description => 'Pickup and return places main season month to'})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.pickup_return_main_season.day_to'},
          {:value => '31',
           :description => 'Pickup and return places main season day to'})

      # -- on season --
      pickup_return_timetable_variable = SystemConfiguration::Variable.get('booking.pickup_return_timetable')
      if pickup_return_timetable_variable.nil?
        timetable = ::Yito::Model::Calendar::Timetable.first_or_create({name: 'booking.pickup_return_timetable'})
        SystemConfiguration::Variable.first_or_create(
            {:name => 'booking.pickup_return_timetable'},
            {:value => timetable.id.to_s,
             :description => 'Pickup and return places timetable'})
      elsif pickup_return_timetable_variable.value == ''
        timetable = ::Yito::Model::Calendar::Timetable.first_or_create({name: 'booking.pickup_return_timetable'})
        SystemConfiguration::Variable.set_value('booking.pickup_return_timetable', timetable.id.to_s)
      end

      # -- out season --
      pickup_return_out_of_season_timetable_variable = SystemConfiguration::Variable.get('booking.pickup_return_timetable_out_of_season')
      if pickup_return_out_of_season_timetable_variable.nil?
        timetable = ::Yito::Model::Calendar::Timetable.first_or_create({name: 'booking.pickup_return_timetable_out_of_season'})
        SystemConfiguration::Variable.first_or_create(
            {:name => 'booking.pickup_return_timetable_out_of_season'},
            {:value => timetable.id.to_s,
             :description => 'Pickup and return places timetable out of season'})
      elsif pickup_return_out_of_season_timetable_variable.value == ''
        timetable = ::Yito::Model::Calendar::Timetable.first_or_create({name: 'booking.pickup_return_timetable_out_of_season'})
        SystemConfiguration::Variable.set_value('booking.pickup_return_timetable_out_of_season', timetable.id.to_s)
      end

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.pickup_return_timetable_out_price'},
        {:value => '0',
         :description => 'Price if the pickup/return is not on pickup/return timetable'})

      # Reservation settings : driver ---------------------------------------------------------------------------------

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.driver_min_age.rules'},
          {:value => 'false',
           :description => 'Young driver rules'})

      driver_age_rule_definition_variable = SystemConfiguration::Variable.get('booking.driver_min_age.rule_definition')
      if driver_age_rule_definition_variable.nil?
        driver_age_rule_definition = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.first_or_create({name: 'booking.driver_min_age.rule_definition'})
        SystemConfiguration::Variable.first_or_create(
            {:name => 'booking.driver_min_age.rule_definition'},
            {:value => driver_age_rule_definition.id.to_s,
                      :description => 'Driver rule definition id for reservation form'})
      elsif driver_age_rule_definition_variable.value == ''
        driver_age_rule_definition = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.first_or_create({name: 'booking.driver_min_age.rule_definition'})
        SystemConfiguration::Variable.set_value('booking.driver_min_age.rule_definition', driver_age_rule_definition.id.to_s)
      end

      # Reservation settings : adults / children ----------------------------------------------------------------------

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.min_adults'},
          {:value => '',
           :description => 'Booking min adults',
           :module => :booking}
      )
      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.max_adults'},
          {:value => '',
           :description => 'Booking max adults',
           :module => :booking}
      )
      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.max_adults_extra'},
          {:value => '',
           :description => 'Booking max adults (extra)',
           :module => :booking}
      )
      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.min_children'},
          {:value => '',
           :description => 'Booking min children',
           :module => :booking}
      )
      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.max_children'},
          {:value => '',
           :description => 'Booking max children',
           :module => :booking}
      )
      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.max_children_extra'},
          {:value => '',
           :description => 'Booking max children (extra)',
           :module => :booking}
      )

      # Notifications -------------------------------------------------------------------------------------------------

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.notification_email'},
          {:value => '',
           :description => 'Bookings notification email',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.send_notifications'},
          {:value => 'true',
           :description => 'Send notifications by email',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.send_notifications_backoffice_reservations'},
          {:value => 'true',
           :description => 'Send notifications for reservations created in the backoffice',
           :module => :booking})

      # SEO
      
      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.page_title'},
        {:value => 'Bookings',
         :description => 'Booking page title',
         :module => :booking})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.page_description'},
        {:value => 'Booking system',
         :description => 'Booking page description',
         :module => :booking})    

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.page_keywords'},
        {:value => 'booking',
         :description => 'Booking page keywords',
         :module => :booking})

      # Turns

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.morning_turns'},
        {:value => '',
         :description => 'Booking morning turns',
         :module => :booking}
        )
      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.afternoon_turns'},
        {:value => '',
         :description => 'Booking morning turns',
         :module => :booking}
        )
      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.night_turns'},
        {:value => '',
         :description => 'Booking morning turns',
         :module => :booking}
        )
      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.duration_of_service'},
        {:value => '',
         :description => 'Booking duration of service',
         :module => :booking}
        )
      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.duration_of_service_extra'},
        {:value => '',
         :description => 'Booking duration of service (extra)',
         :module => :booking}
        )
      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.duration_of_service_extra_turns'},
        {:value => '',
         :description => 'Booking duration of service (extra) turns',
         :module => :booking}
        )

      # Timetable (scheduler)

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.scheduler_start_time'},
        {:value => '',
         :description => 'Booking scheduler start time',
         :module => :booking})
      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.scheduler_finish_time'},
        {:value => '',
         :description => 'Booking scheduler finish time',
         :module => :booking})

      # Price calculation

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.renting_calendar_season_mode'},
          {:value => 'first_day',
           :description => 'Calendar for season: first_day, default',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.use_factors_in_rates'},
          {:value => 'false',
           :description => 'Use factors in rates definition',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.use_factors_in_extras_rates'},
          {:value => 'false',
           :description => 'Use factors in rates definition',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.new_season_definition_instance_for_category'},
          {:value => 'false',
           :description => 'Each product category has it\'s own season definition instance',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.new_factor_definition_instance_for_category'},
          {:value => 'false',
           :description => 'Each product category has it\'s own factor definition instance',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.products.allow_deposit'},
          {:value => 'false',
           :description => 'It allows to setup if the products can define a deposit',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.booking_amount_includes_deposit'},
          {:value => 'true',
           :description => 'The deposit (booking amount) to confirm the reservation includes the deposit',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.total_cost_includes_deposit'},
          {:value => 'false',
           :description => 'The deposit is included in the total cost',
           :module => :booking})

      # Multiple rental locations

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.multiple_rental_locations'},
          {:value => 'false',
           :description => 'There are multiple rental locations',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.resource_availability_by_rental_location_storage'},
          {:value => 'false',
           :description => 'A resource located in an storage. Its only available for rental locations linked to the storage',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.multiple_rental_locations_allow_operator_all_locations'},
          {:value => 'false',
           :description => 'Check if the booking operators can show all locations in pickup/return report',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.multiple_rental_locations_pickup_return_same_location'},
          {:value => 'true',
           :description => 'Check if the pickup and return place must belong to the same location',
           :module => :booking})

      # Frontend

      SystemConfiguration::Variable.first_or_create(
          {name: 'booking.front_end_prefix'},
          {value: '',
           description: 'The front-end site url if the front-end is detached from the backoffice',
           module: :booking}
      )

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.inner_reservation_engine'},
          {:value => 'true',
           :description => 'Uses the inner reservation engine',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create({:name => 'site.booking_manager_front_page'},
                                                    {:value => '',
                                                     :description => 'Booking manager front page (dashboard)',
                                                     :module => :booking})

      SystemConfiguration::Variable.first_or_create({:name => 'site.booking_operator_front_page'},
                                                    {:value => '',
                                                     :description => 'Booking operator front page (dashboard)',
                                                     :module => :booking})

      # Contract      
      SystemConfiguration::Variable.first_or_create({:name => 'booking.contract_logo'}, 
                                                    {:value => '',
                                                     :description => 'Booking contract logo', 
                                                     :module => :booking})

      SystemConfiguration::Variable.first_or_create({:name => 'booking.use_custom_contract'}, 
                                                    {:value => 'false',
                                                     :description => 'Booking use custom contract', 
                                                     :module => :booking})

      #
      # Rates setup : Seasons (general), factors (general)
      #
      unless season_definition = Yito::Model::Rates::SeasonDefinition.first(name: 'general')
        season_definition = Yito::Model::Rates::SeasonDefinition.create(name: 'general', description: 'Temporadas generales')
        season = Yito::Model::Rates::Season.create(season_definition: season_definition, name: '1',
          from_day: 1, from_month: 1, to_day: 31, to_month: 12)
      end

      unless factor_definition = Yito::Model::Rates::FactorDefinition.first(name: 'general')
        factor_definition = Yito::Model::Rates::FactorDefinition.create(name: 'general', description: 'Factores generales')
        factor_1 = Yito::Model::Rates::Factor.create(factor_definition: factor_definition, from: 1, to: 1, factor: 2)
        factor_2 = Yito::Model::Rates::Factor.create(factor_definition: factor_definition, from: 2, to: 2, factor: 1.5)
        factor_3 = Yito::Model::Rates::Factor.create(factor_definition: factor_definition, from: 3, to: 3, factor: 1.1)
      end

      #
      # Calendars : Three types of events for this business : not_available, payment_enabled and activity
      #
      if Yito::Model::Calendar::EventType.count(:name => 'not_available') == 0
        Yito::Model::Calendar::EventType.create(:name => 'not_available',
                                              :description => 'Not available')
      end
      if Yito::Model::Calendar::EventType.count(:name => 'payment_enabled') == 0
        Yito::Model::Calendar::EventType.create(:name => 'payment_enabled',
                                                :description => 'Payment enabled')
      end
      if Yito::Model::Calendar::EventType.count(:name => 'activity') == 0
        Yito::Model::Calendar::EventType.create(:name => 'activity',
                                                :description => 'Programmed activity')
      end

      #
      # Products families (types of business)
      #
      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'car'},
    {
        :name => 'Alquiler de vehículos (coches, motos, ...)',
        :business_type => :vehicle_rental,
        :product_type => :category_of_resources,
        :business_activity => :rental,
        :presentation_order => 1,
        :frontend => :dates,
        :driver => true,
        :driver_date_of_birth => false,
        :driver_license => true,
        :guests => false,
        :flight => true,
        :pickup_return_place => true,
        :time_to_from => true,
        :start_date_literal => :pickup,
        :cycle_of_24_hours => true,
        :fuel => true,
        :stock_model => true,
        :stock_plate => true,
        :product_price_definition_type => :season,
        :product_price_definition_season_definition => season_definition,
        :product_price_definition_factor_definition => factor_definition,
        :product_price_definition_units_management => :detailed,
        :product_price_definition_units_management_value => 7,
        :extras_price_definition_type => :no_season,
        :extras_price_definition_season_definition => season_definition,
        :extras_price_definition_factor_definition => factor_definition,
        :extras_price_definition_units_management => :unitary,
        :extras_price_definition_units_management_value => 1,
        :starting_date => :pickup_return_date,
        :allow_extras => true,
        :multiple_locations => true,
        :multiple_storages => true,
        :pax => false
      })

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'car_vehicles'},
    {
        :name => 'Alquiler vehículos individuales (sin categorías)',
        :business_type => :vehicle_rental,
        :product_type => :resource,
        :business_activity => :rental,
        :presentation_order => 2,
        :frontend => :dates,
        :driver => true,
        :driver_date_of_birth => false,
        :driver_license => true,
        :guests => false,
        :flight => true,
        :pickup_return_place => true,
        :time_to_from => true,
        :start_date_literal => :pickup,
        :cycle_of_24_hours => true,
        :fuel => true,
        :stock_model => true,
        :stock_plate => true,
        :product_price_definition_type => :season,
        :product_price_definition_season_definition => season_definition,
        :product_price_definition_factor_definition => factor_definition,
        :product_price_definition_units_management => :detailed,
        :product_price_definition_units_management_value => 7,
        :extras_price_definition_type => :no_season,
        :extras_price_definition_season_definition => season_definition,
        :extras_price_definition_factor_definition => factor_definition,
        :extras_price_definition_units_management => :unitary,
        :extras_price_definition_units_management_value => 1,
        :starting_date => :pickup_return_date,
        :allow_extras => true,
        :multiple_locations => true,
        :multiple_storages => true,
        :pax => false        
      })


      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'kayak'},
    {
        :name => 'Alquiler y/o excursiones en kayak',
        :business_type => :category_resources,
        :product_type => :category_of_resources,
        :business_activity => :both_rental_activities_tours,
        :presentation_order => 3,
        :frontend => :shopcart,
        :driver => true,
        :driver_date_of_birth => false,
        :driver_license => false,
        :guests => false,
        :pickup_return_place => false,
        :time_to_from => true,
        :start_date_literal => :pickup,
        :height => true,
        :height_mandatory => true,
        :height_values => '150-175,175-200',
        :weight => true,
        :weight_mandatory => true,
        :weight_values => '<= 75Kg,75Kg',
        :cycle_of_24_hours => false,
        :fuel => false,
        :stock_model => true,
        :stock_plate => false,
        :product_price_definition_type => :season,
        :product_price_definition_season_definition => season_definition,
        :product_price_definition_factor_definition => factor_definition,
        :product_price_definition_units_management => :detailed,
        :product_price_definition_units_management_value => 7,
        :extras_price_definition_type => :no_season,
        :extras_price_definition_season_definition => season_definition,
        :extras_price_definition_factor_definition => factor_definition,
        :extras_price_definition_units_management => :unitary,
        :extras_price_definition_units_management_value => 1,
        :starting_date => :pickup_return_date,
        :allow_extras => true,
        :multiple_locations => true,
        :multiple_storages => true,
        :pax => true   
      })

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'place'},
        {
         :name => 'Alojamientos (hotel, hostal, ...)',
         :business_type => :accommodation,
         :product_type => :category_of_resources,
         :business_activity => :rental,
         :frontend => :categories,
         :presentation_order => 4,
         :driver => false,
         :guests => true,
         :flight => true,
         :pickup_return_place => false,
         :time_to_from => false,
         :start_date_literal => :arrival,
         :cycle_of_24_hours => true,
         :fuel => false,
         :stock_model => false,
         :stock_plate => false,
         :product_price_definition_type => :season,
         :product_price_definition_season_definition => season_definition,
         :product_price_definition_factor_definition => factor_definition,
         :product_price_definition_units_management => :detailed,
         :product_price_definition_units_management_value => 7,
         :extras_price_definition_type => :no_season,
         :extras_price_definition_season_definition => season_definition,
         :extras_price_definition_factor_definition => factor_definition,
         :extras_price_definition_units_management => :unitary,
         :extras_price_definition_units_management_value => 1,
         :starting_date => :checkin_checkout,
         :allow_extras => true,
         :multiple_locations => false,        
         :multiple_storages => false,
         :pax => false   
        })

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'bike'},
        {
         :name => 'Alquiler y/o rutas en bicicleta',
         :business_type => :category_resources,
         :product_type => :category_of_resources,
         :business_activity => :both_rental_activities_tours,
         :frontend => :shopcart,
         :presentation_order => 5,
         :driver => false,
         :guests => false,
         :flight => false,
         :pickup_return_place => false,
         :time_to_from => true,
         :start_date_literal => :pickup,
         :cycle_of_24_hours => false,
         :fuel => false,
         :stock_model => true,
         :stock_plate => false,
         :product_price_definition_type => :season,
         :product_price_definition_season_definition => season_definition,
         :product_price_definition_factor_definition => factor_definition,
         :product_price_definition_units_management => :detailed,
         :product_price_definition_units_management_value => 7,
         :extras_price_definition_type => :no_season,
         :extras_price_definition_season_definition => season_definition,
         :extras_price_definition_factor_definition => factor_definition,
         :extras_price_definition_units_management => :unitary,
         :extras_price_definition_units_management_value => 1,
         :starting_date => :pickup_return_date,
         :allow_extras => true,
         :multiple_locations => true,        
         :multiple_storages => true,
         :pax => false
        })

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'boat_charter'},
    {
        :name => 'Charter naútico',
        :business_type => :boat_charter,
        :product_type => :resource,        
        :business_activity => :rental,
        :presentation_order => 6,
        :frontend => :dates,
        :driver => true,
        :driver_date_of_birth => false,
        :driver_license => false,
        :guests => false,
        :flight => false,
        :height => false,
        :height_mandatory => false,
        :weight => false,
        :weight_mandatory => false,
        :pickup_return_place => false,
        :time_to_from => false,
        :time_start => '10:00',
        :time_end => '20:00',
        :start_date_literal => :pickup,
        :driver_literal => :contact,
        :cycle_of_24_hours => false,
        :named_resources => false,
        :fuel => false,
        :stock_model => true,
        :stock_plate => false,
        :product_price_definition_type => :season,
        :product_price_definition_season_definition => season_definition,
        :product_price_definition_factor_definition => factor_definition,
        :product_price_definition_units_management => :detailed,
        :product_price_definition_units_management_value => 7,
        :extras_price_definition_type => :no_season,
        :extras_price_definition_season_definition => season_definition,
        :extras_price_definition_factor_definition => factor_definition,
        :extras_price_definition_units_management => :unitary,
        :extras_price_definition_units_management_value => 1,
        :starting_date => :start_end,
        :allow_extras => true,
        :multiple_locations => false,        
        :multiple_storages => false,
        :pax => false
    })


    Yito::Model::Booking::ProductFamily.first_or_create(
      {:code => 'tours'},
      {
          :name => 'Tours',
          :business_type => :tours,
          :product_type => :resource, #Not necessary because it's for renting
          :business_activity => :activities_tours,
          :presentation_order => 7,
          :frontend => :dates,
          :product_price_definition_type => :no_season,
          :product_price_definition_season_definition => nil,
          :product_price_definition_factor_definition => nil,
          :product_price_definition_units_management => :unitary,
          :product_price_definition_units_management_value => 1,
          :extras_price_definition_type => :no_season,
          :extras_price_definition_season_definition => nil,
          :extras_price_definition_factor_definition => nil,
          :extras_price_definition_units_management => :unitary,
          :extras_price_definition_units_management_value => 1,
          :starting_date => :pickup_return_date,
          :allow_extras => true,
          :multiple_locations => true,        
          :multiple_storages => false,
          :pax => false
      })

      Yito::Model::Booking::ProductFamily.first_or_create(
          {:code => 'activities'},
          {
              :name => 'Actividades',
              :business_type => :activities,
              :product_type => :resource, #Not necessary because it's for renting              
              :business_activity => :activities_tours,
              :presentation_order => 8,
              :frontend => :dates,
              :product_price_definition_type => :no_season,
              :product_price_definition_season_definition => nil,
              :product_price_definition_factor_definition => nil,
              :product_price_definition_units_management => :unitary,
              :product_price_definition_units_management_value => 1,
              :extras_price_definition_type => :no_season,
              :extras_price_definition_season_definition => nil,
              :extras_price_definition_factor_definition => nil,
              :extras_price_definition_units_management => :unitary,
              :extras_price_definition_units_management_value => 1,
              :starting_date => :pickup_return_date,
              :allow_extras => true,
              :multiple_locations => true,        
              :multiple_storages => false,
              :pax => false
          })

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'other'},
    {
        :name => 'Otros (alquiler)',
        :business_type => :category_resources,
        :business_activity => :rental,
        :product_type => :category_of_resources,
        :frontend => :dates,
        :presentation_order => 99,
        :driver => false,
        :guests => false,
        :flight => false,
        :pickup_return_place => false,
        :time_to_from => true,
        :start_date_literal => :pickup,
        :cycle_of_24_hours => false,
        :fuel => false,
        :product_price_definition_type => :season,
        :product_price_definition_season_definition => season_definition,
        :product_price_definition_factor_definition => factor_definition,
        :product_price_definition_units_management => :detailed,
        :product_price_definition_units_management_value => 7,
        :extras_price_definition_type => :no_season,
        :extras_price_definition_season_definition => season_definition,
        :extras_price_definition_factor_definition => factor_definition,
        :extras_price_definition_units_management => :unitary,
        :extras_price_definition_units_management_value => 1,
        :starting_date => :start_end,
        :allow_extras => true,
        :multiple_locations => true,        
        :multiple_storages => true,
        :pax => false
      })

      #
      # Users groups : booking manager - booking operator - charge supplier
      #

      Users::Group.first_or_create({:group => 'booking_manager'},
          {:name => 'Booking manager', :description => 'Booking manager'})

      Users::Group.first_or_create({:group => 'booking_operator'},
                                   {:name => 'Booking operator', :description => 'Booking operator'})
      
      Users::Group.first_or_create({:group => 'booking_charge_supplier'},
                                   {:name => 'Booking charge supplier', :description => 'Booking charge supplier'})

      Users::Group.first_or_create({group: 'booking_customer'},
                                   {name: 'Booking customer', description: 'Booking customer'} )

      Users::Group.first_or_create({group: 'booking_supplier'},
                                   {name: 'Booking supplier', description: 'Booking supplier'})

      Users::Group.first_or_create({group: 'booking_agent'},
                                   {name: 'Booking agent', description: 'Booking agent'} )

      Users::Group.first_or_create({group: 'booking_agency'},
                                   {name: 'Booking agency', description: 'Booking agency'})

      #
      # Notification templates
      #
      ContentManagerSystem::Template.first_or_create({:name => 'booking_manager_notification'},
          {:description=>'Mensaje que se envía al gestor de reservas al recibir una nueva solicitud',
           :text => BookingDataSystem::Booking.manager_notification_template})

      ContentManagerSystem::Template.first_or_create({:name => 'booking_manager_notification_pay_now'},
          {:description => 'Mensaje que se envía al gestor de reservas cuando un cliente realiza una solicitud de reserva con pago',
           :text => BookingDataSystem::Booking.manager_notification_pay_now_template})

      ContentManagerSystem::Template.first_or_create({:name => 'booking_confirmation_manager_notification'},
          {:description => 'Mensaje que se envía al gestor de reservas cuando se confirma una reserva',
           :text => BookingDataSystem::Booking.manager_confirm_notification_template})

      ContentManagerSystem::Template.first_or_create({:name => 'booking_customer_req_notification'},
          {:description=>'Mensaje que se envía al cliente cuando realiza solicitud de reserva (sin pago)',
           :text => BookingDataSystem::Booking.customer_notification_booking_request_template}) 

      ContentManagerSystem::Template.first_or_create({:name => 'booking_customer_req_pay_now_notification'},
          {:description=>'Mensaje que se envía al cliente cuando realiza solicitud de reserva (con pago)',
           :text => BookingDataSystem::Booking.customer_notification_request_pay_now_template}) 

      ContentManagerSystem::Template.first_or_create({:name => 'booking_customer_notification'},
          {:description=>'Mensaje que se envía al cliente cuando se confirma la solicitud de reserva',
           :text => BookingDataSystem::Booking.customer_notification_booking_confirmed_template}) 

      ContentManagerSystem::Template.first_or_create({:name => 'booking_customer_notification_payment_enabled'},
          {:description=>'Mensaje que se envía al cliente cuando se habilita el pago reserva',
           :text => BookingDataSystem::Booking.customer_notification_payment_enabled_template}) 

      ContentManagerSystem::Template.first_or_create({:name => 'booking_contract'},
          {:description=>'Contrato',
           :text => ::Yito::Model::Booking::Templates.contract}) 

      ContentManagerSystem::Template.first_or_create({:name => 'booking_summary_message'},
          {:description=>'Mensaje al finalizar la reserva',
           :text => ::Yito::Model::Booking::Templates.summary_message})

      #
      # Creates the calendar and the events for the booking journal (pickup/return integration)
      #
      unless booking_journal_calendar = Yito::Model::Calendar::Calendar.first(:name => 'booking_journal')
        booking_journal_calendar = Yito::Model::Calendar::Calendar.create({:name => 'booking_journal', :description => 'Booking journal calendar'})
      end  
      
      if Yito::Model::Calendar::EventType.count(:name => 'booking_pickup') == 0
        booking_pickup_event = Yito::Model::Calendar::EventType.create(name: 'booking_pickup', description: 'Entrega')
        Yito::Model::Calendar::EventTypeCalendar.create(calendar: booking_journal_calendar, event_type: booking_pickup_event)
      end
      
      if Yito::Model::Calendar::EventType.count(:name => 'booking_return') == 0
        booking_return_event = Yito::Model::Calendar::EventType.create(name: 'booking_return', description: 'Recogida')
        Yito::Model::Calendar::EventTypeCalendar.create(calendar: booking_journal_calendar, event_type: booking_return_event)
      end

      if Yito::Model::Booking::RentalStorage.count == 0
        booking_storage = Yito::Model::Booking::RentalStorage.first_or_create({name: 'Central'},
                                                                              {name: 'Central',
                                                                               address: {street: '', city: '', country: 'España'}})
        Yito::Model::Booking::RentalLocation.first_or_create({code: 'central'},
                                                             {name: 'Central',
                                                              rental_storage: booking_storage,
                                                              address: {street: '', city: '', country: 'España'}})
      end 

    end
    
    # ----------- Invoices integration ----------------------

    #
    # Invoice source
    #
    def invoice_sources(context={})
       [:booking] 
    end  

    # ----------- Blocks ------------------------------------

    # Retrieve all the blocks defined in this module 
    # 
    # @param [Hash] context
    #   The context
    #
    # @return [Array]
    #   The blocks defined in the module
    #
    #   An array of Hash which the following keys:
    #
    #     :name         The name of the block
    #     :module_name  The name of the module which defines the block
    #     :theme        The theme
    #
    def block_list(context={})
    
      app = context[:app]
    
      [{:name => 'booking_admin_menu',
        :module_name => :booking,
        :theme => Themes::ThemeManager.instance.selected_theme.name},
       {:name => 'booking_operator_menu',
        :module_name => :booking,
        :theme => Themes::ThemeManager.instance.selected_theme.name}
      ]
        
    end

    # Get a block representation 
    #
    # @param [Hash] context
    #   The context
    #
    # @param [String] block_name
    #   The name of the block
    #
    # @return [String]
    #   The representation of the block
    #    
    def block_view(context, block_name)
    
      app = context[:app]
        
      locals = {}

      case block_name
        when 'booking_operator_menu', 'booking_admin_menu'
          today = Date.today
          year = today.year

          use_factors = SystemConfiguration::Variable.get_value('booking.use_factors_in_rates','false').to_bool

          booking_renting, booking_activities = app.mybooking_plan_type
          addons = app.mybooking_addons

          menu_locals = {booking_renting: booking_renting,
                         booking_activities: booking_activities,
                         addons: addons,
                         use_factors: use_factors,
                         use_inner_reservation_engine: SystemConfiguration::Variable.get_value('booking.inner_reservation_engine','false').to_bool}
          if booking_renting
            menu_locals.store(:pending_confirmation, BookingDataSystem::Booking.count_pending_confirmation_reservations(year))
            menu_locals.store(:today_pickup, BookingDataSystem::Booking.pickup_list(today, today, nil, true).size) #BookingDataSystem::Booking.count_pickup(today))
            menu_locals.store(:today_return, BookingDataSystem::Booking.return_list(today, today, nil, true).size)#BookingDataSystem::Booking.count_delivery(today))
            menu_locals.store(:pending_assignation, BookingDataSystem::Booking.pending_of_assignation.size)
            menu_locals.store(:planning_conflicts_count, BookingDataSystem::Booking.overbooking_conflicts.size)
          end
          if booking_activities
            menu_locals.store(:pending_confirmation_activities, ::Yito::Model::Order::Order.count_pending_confirmation_orders(year))
            menu_locals.store(:today_start_activities, ::Yito::Model::Order::Order.count_start(today))
          end
          menu_locals.store(:multiple_rental_locations, BookingDataSystem::Booking.multiple_rental_locations)
          product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          menu_locals.store(:product_family, product_family)

          if block_name == 'booking_admin_menu'
            begin
              p "product_family: #{product_family.inspect} #{product_family.accommodation?}"
              if product_family.accommodation?
                app.partial(:booking_menu_hostel, :locals => menu_locals)
              else
                app.partial(:booking_menu, :locals => menu_locals)
              end
            rescue => error
              p "error: #{error.inspect}"
            end
          else
            app.partial(:booking_operator_menu, :locals => menu_locals)
          end

      end
      
    end

    # ========= Page Building ============

    #
    # Page process
    #
    # @param [Context]
    #
    # @return [Hash]
    #
    #  A Hash where each key represents a variable, the region to insert the content, and the value is an array of blocks
    #
    def page_preprocess(page, context={})

      app = context[:app]

      result = {}

      if page.admin_page
        if app.user and app.user.belongs_to?('booking_manager')
          menu = block_view(context, 'booking_admin_menu')
          result.store(:sidebar_menu, [menu])
        elsif app.user and app.user.belongs_to?('booking_operator')
          menu = block_view(context, 'booking_operator_menu')
          result.store(:sidebar_menu, [menu])
        end
      end

      return result

    end
    
    #
    # It gets the scripts used by the module
    #
    # @param [Context]
    #
    # @return [Array]
    #   An array which contains the css resources used by the module
    #
    #def page_script(context={}, page)
    #
    #  ['/booking_js.js'] if ((defined?MY_BOOKING_FRONTEND) && (MY_BOOKING_FRONTEND == '3.0')) || (!defined?MY_BOOKING_FRONTEND)
    #
    #end

    # --------- Menus --------------------
    
    #
    # It defines the admin menu menu items
    #
    # @return [Array]
    #  Menu definition
    #
    def menu(context={})
      
      app = context[:app]

      menu_items = [{:path => '/apps/bookings',              
                     :options => {:title => app.t.system_admin_menu.apps.bookings_menu.title,
                                  :description => 'Bookings',
                                  :module => :booking,
                                  :weight => 5}
                    },
                    {:path => '/apps/bookings/booking-categories',              
                     :options => {:title => app.t.system_admin_menu.apps.bookings_menu.booking_categories,
                                  :link_route => "/admin/booking-categories",
                                  :description => 'Booking categories management',
                                  :module => :booking,
                                  :weight => 4}
                    },
                    {:path => '/apps/bookings/bookings',              
                     :options => {:title => app.t.system_admin_menu.apps.bookings_menu.booking_items,
                                  :link_route => "/admin/booking-items",
                                  :description => 'Booking items management',
                                  :module => :booking,
                                  :weight => 3}
                    },                                        
                    {:path => '/apps/bookings/bookings',              
                     :options => {:title => app.t.system_admin_menu.apps.bookings_menu.bookings,
                                  :link_route => "/admin/bookings",
                                  :description => 'Booking management',
                                  :module => :booking,
                                  :weight => 2}
                    },
                    {:path => '/apps/bookings/scheduler',              
                     :options => {:title => app.t.system_admin_menu.apps.bookings_menu.bookings_scheduler,
                                  :link_route => "/admin/bookings/scheduler",
                                  :description => 'Booking scheduler',
                                  :module => :booking,
                                  :weight => 1}
                    }                    
                    ]                      
    
    end  

    # ========= Routes ===================
            
    # routes
    #
    # Define the module routes, that is the url that allow to access the funcionality defined in the module
    #
    #
    def routes(context={})
    
      routes = [{:path => '/reserva',
      	         :regular_expression => /^\/reserva/, 
                 :title => 'Reserva' , 
                 :description => 'Formulario para realizar reserva',
                 :fit => 1,
                 :module => :booking},
               {:path => '/apps/bookings/booking-categories',
                  :regular_expression => /^\/admin\/booking-categories/,
                  :title => 'Booking categories',
                  :fit => 1,
                  :module => :booking}, 
                {:path => '/apps/bookings/booking-items',
                  :regular_expression => /^\/admin\/booking-items/,
                  :title => 'Booking items',
                  :fit => 1,
                  :module => :booking},                 
                {:path => '/apps/bookings/bookings',
                 :regular_expression => /^\/admin\/bookings/, 
                 :title => 'Bookings', 
                 :description => 'Booking management',
                 :fit => 1,
                 :module => :booking },   
                {:path => '/apps/bookings/scheduler',
                 :regular_expression => /^\/admin\/bookings\/scheduler/, 
                 :title => 'Scheduler', 
                 :description => 'Booking scheduler',
                 :fit => 1,
                 :module => :booking }                                                  
               ]
        
    end
    
    #
    # ---------- Path prefixes to be ignored ----------
    #

    #
    # Ignore the following path prefixes in language processor
    #
    #def ignore_path_prefix_language(context={})
    #  %w(/p/booking/payment-gateway /p/booking/pay /p/booking/summary /p/mybooking /p/activities/add-to-shopping-cart /p/activity/remove-to-shopping-cart /p/activities/shopping-cart /p/activities/shopping-cart-checkout)
    #end

    #
    # Ignore the following path prefix in cms
    #
    #def ignore_path_prefix_cms(context={})
    #  %w(/p/booking/payment-gateway /p/booking/pay /p/booking/summary /p/mybooking /p/activities/add-to-shopping-cart /p/activity/remove-to-shopping-cart /p/activities/shopping-cart /p/activities/shopping-cart-checkout)
    #end

    #
    # Ignore the following path prefix in breadcrumb
    #
    #def ignore_path_prefix_breadcrumb(context={})
    #  %w(/p/booking/payment-gateway /p/booking/pay /p/booking/summary /p/mybooking /p/activities/add-to-shopping-cart /p/activity/remove-to-shopping-cart /p/activities/shopping-cart /p/activities/shopping-cart-checkout)
    #end

  end
end