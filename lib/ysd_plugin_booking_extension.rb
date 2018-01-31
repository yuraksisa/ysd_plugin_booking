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

      #
      # Common settings
      #

      SystemConfiguration::Variable.first_or_create(
        {name: 'booking.front_end_prefix'},
        {value: '',
                  description: 'The front-end site url if the front-end is detached from the backoffice',
                  module: :booking}
      )
      
      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.mode'},
        {:value => 'rent',
         :description => 'Booking mode: rent, restaurant',
         :module => :booking})

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
        {:name => 'booking.notification_email'},
        {:value => '',
         :description => 'Bookings notification email',
         :module => :booking})      

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.deposit'},
        {:value => '40',
         :description => 'Deposit percentage or 0 if no deposit management',
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

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.allow_total_payment'},
        {:value => 'true',
         :description => 'Allow total payment. Values: true, false',
         :module => :booking})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.payment'},
        {:value => 'false',
         :description => 'Integrate the payment in the booking process. Values: true, false',
         :module => :booking})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.payment_cadence'},
        {:value => '48',
         :description => 'Cadence in hours from the reservation date to today',
         :module => :booking})

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
          {:name => 'booking.send_notifications'},
          {:value => 'true',
           :description => 'Send notifications by email',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.send_notifications_backoffice_reservations'},
          {:value => 'true',
           :description => 'Send notifications for reservations created in the backoffice',
           :module => :booking})      

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.min_days'},
        {:value => '1',
         :description => 'Minimum number of days you must book',
         :module => :booking})

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
        {:name => 'booking.default_booking_catalog.code'},
        {:value => '',
         :description => 'Default booking catalog',
         :module => 'booking'})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.pickup_return_place_definition'},
          {:value => '',
           :description => 'Pickup and return place definition'})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.allow_custom_pickup_return_place'},
        {:value => 'false',
         :description => 'Allow custom pickup and return places'})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.custom_pickup_return_place_price'},
        {:value => '0',
         :description => 'Custom pickup and return places cost'})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.pickup_return_timetable'},
        {:value => '',
         :description => 'Pickup and return places timetable'})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.pickup_return_timetable_out_price'},
        {:value => '0',
         :description => 'Price if the pickup/return is not on pickup/return timetable'})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.driver_min_age.rules'},
          {:value => 'false',
           :description => 'Young driver rules'})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.driver_min_age.rule_definition'},
          {:value => '',
           :description => 'Driver rule definition id for reservation form'}
      )

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.driver_min_age.booking_driver_edition'},
          {:value => 'false',
           :description => 'Allow editing the driver age and driver license date in the driver block'}
      )

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.renting'},
        {:value => 'true',
         :description => 'Allow renting integration'})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.activities'},
        {:value => 'false',
         :description => 'Allow activities integration'})
      
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
      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.people_resources'},
        {:value => '',
         :description => 'Booking people resources',
         :module => :booking})
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
      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.renting_calendar_season_mode'},
        {:value => 'first_day',
         :description => 'Calendar for season: first_day, default',
         :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.multiple_rental_locations'},
          {:value => 'false',
           :description => 'There are multiple rental locations',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.multiple_rental_locations_allow_operator_all_locations'},
          {:value => 'false',
           :description => 'Check if the booking operators can show all locations in pickup/return report',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.use_factors_in_rates'},
          {:value => 'false',
           :description => 'Use factors in rates definition',
           :module => :booking})

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
        :product_type => :category_of_resources,
        :product_price_definition_type => :season,
        :product_price_definition_season_definition => season_definition,
        :product_price_definition_factor_definition => factor_definition,
        :product_price_definition_units_management => :detailed,
        :product_price_definition_units_management_value => 7,
        :extras_price_definition_type => :no_season,
        :extras_price_definition_season_definition => season_definition,
        :extras_price_definition_factor_definition => factor_definition,
        :extras_price_definition_units_management => :unitary,
        :extras_price_definition_units_management_value => 1
      })

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'kayak'},
    {
        :name => 'Alquiler y/o excursiones en kayak',
        :presentation_order => 2,
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
        :product_type => :category_of_resources,
        :product_price_definition_type => :season,
        :product_price_definition_season_definition => season_definition,
        :product_price_definition_factor_definition => factor_definition,
        :product_price_definition_units_management => :detailed,
        :product_price_definition_units_management_value => 7,
        :extras_price_definition_type => :no_season,
        :extras_price_definition_season_definition => season_definition,
        :extras_price_definition_factor_definition => factor_definition,
        :extras_price_definition_units_management => :unitary,
        :extras_price_definition_units_management_value => 1
      })

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'place'},
        {
         :name => 'Alojamientos (hotel, hostal, ...)',
         :frontend => :categories,
         :presentation_order => 3,
         :driver => false,
         :guests => true,
         :flight => true,
         :pickup_return_place => false,
         :time_to_from => false,
         :start_date_literal => :arrival,
         :cycle_of_24_hours => true,
         :fuel => false,
         :product_type => :category_of_resources,
         :product_price_definition_type => :season,
         :product_price_definition_season_definition => season_definition,
         :product_price_definition_factor_definition => factor_definition,
         :product_price_definition_units_management => :detailed,
         :product_price_definition_units_management_value => 7,
         :extras_price_definition_type => :no_season,
         :extras_price_definition_season_definition => season_definition,
         :extras_price_definition_factor_definition => factor_definition,
         :extras_price_definition_units_management => :unitary,
         :extras_price_definition_units_management_value => 1
        })

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'bike'},
        {
         :name => 'Alquiler y/o rutas en bicicleta',
         :frontend => :shopcart,
         :presentation_order => 4,
         :driver => false,
         :guests => false,
         :flight => false,
         :pickup_return_place => false,
         :time_to_from => true,
         :start_date_literal => :pickup,
         :cycle_of_24_hours => false,
         :fuel => false,
         :product_type => :category_of_resources,
         :product_price_definition_type => :season,
         :product_price_definition_season_definition => season_definition,
         :product_price_definition_factor_definition => factor_definition,
         :product_price_definition_units_management => :detailed,
         :product_price_definition_units_management_value => 7,
         :extras_price_definition_type => :no_season,
         :extras_price_definition_season_definition => season_definition,
         :extras_price_definition_factor_definition => factor_definition,
         :extras_price_definition_units_management => :unitary,
         :extras_price_definition_units_management_value => 1
        })

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'other'},
    {
        :name => 'Otros',
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
        :product_type => :category_of_resources,
        :product_price_definition_type => :season,
        :product_price_definition_season_definition => season_definition,
        :product_price_definition_factor_definition => factor_definition,
        :product_price_definition_units_management => :detailed,
        :product_price_definition_units_management_value => 7,
        :extras_price_definition_type => :no_season,
        :extras_price_definition_season_definition => season_definition,
        :extras_price_definition_factor_definition => factor_definition,
        :extras_price_definition_units_management => :unitary,
        :extras_price_definition_units_management_value => 1
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
    
      [{:name => 'booking_selector',
        :module_name => :booking,
        :theme => Themes::ThemeManager.instance.selected_theme.name},
       {:name => 'booking_selector_inline',
        :module_name => :booking,
        :theme => Themes::ThemeManager.instance.selected_theme.name},
       {:name => 'booking_admin_menu',
        :module_name => :booking,
        :theme => Themes::ThemeManager.instance.selected_theme.name},
       {:name => 'booking_operator_menu',
        :module_name => :booking,
        :theme => Themes::ThemeManager.instance.selected_theme.name},
       {:name => 'booking_activities_shopping_cart',
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
      locals.store(:booking_min_days,
        SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i)
      locals.store(:booking_item_family, 
        ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))
      locals.store(:booking_item_type,
        SystemConfiguration::Variable.get_value('booking.item_type')) 
      locals.store(:booking_allow_custom_pickup_return_place,
        SystemConfiguration::Variable.get_value('booking.allow_custom_pickup_return_place', 'false').to_bool)

      young_driver_rules = SystemConfiguration::Variable.get_value('booking.driver_min_age.rules', 'false').to_bool
      young_driver_rule_definition = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(SystemConfiguration::Variable.get_value('booking.driver_min_age.rule_definition'))

      locals.store(:driver_age_rules, young_driver_rules)
      locals.store(:driver_age_rule_definition, young_driver_rule_definition)
      
      locals.store(:booking_js, '')      

      case block_name
        when 'booking_activities_shopping_cart'
          shopping_cart = ::Yito::Model::Order::ShoppingCart.get(app.session[:shopping_cart_id]) || ::Yito::Model::Order::ShoppingCart.new
          app.partial(:activities_shopping_cart, :locals => {shopping_cart: shopping_cart}) 
        when 'booking_selector'    
          app.partial(:booking_selector, :locals => locals)
        when 'booking_selector_inline'         
          app.partial(:booking_selector_inline, :locals => locals)
        when 'booking_operator_menu', 'booking_admin_menu'
          today = Date.today
          year = today.year

          booking_mode = SystemConfiguration::Variable.get_value('booking.mode','rent')
          use_factors = SystemConfiguration::Variable.get_value('booking.use_factors_in_rates','false').to_bool

          booking_renting, booking_activities = app.mybooking_plan
          addons = app.mybooking_addons

          if booking_mode == 'rent'
            menu_locals = {booking_renting: booking_renting,
                           booking_activities: booking_activities,
                           addons: addons,
                           use_factors: use_factors}
            if booking_renting
              menu_locals.store(:pending_confirmation, BookingDataSystem::Booking.count_pending_confirmation_reservations(year))
              menu_locals.store(:today_pickup, BookingDataSystem::Booking.pickup_list(today, today, nil, true).size) #BookingDataSystem::Booking.count_pickup(today))
              menu_locals.store(:today_return, BookingDataSystem::Booking.return_list(today, today, nil, true).size)#BookingDataSystem::Booking.count_delivery(today))
              menu_locals.store(:pending_assignation, BookingDataSystem::Booking.pending_of_assignation.size)
            end
            if booking_activities
              menu_locals.store(:pending_confirmation_activities, ::Yito::Model::Order::Order.count_pending_confirmation_orders(year))
              menu_locals.store(:today_start_activities, ::Yito::Model::Order::Order.count_start(today))
            end
            menu_locals.store(:multiple_rental_locations, SystemConfiguration::Variable.get_value('booking.multiple_rental_locations', 'false').to_bool)
            if block_name == 'booking_admin_menu'
              begin
                app.partial(:booking_menu, :locals => menu_locals)
              rescue => error
                p "error: #{error.inspect}"
              end
            else
              app.partial(:booking_operator_menu, :locals => menu_locals)
            end
          elsif booking_mode == 'restaurant'
            app.partial(:booking_menu_restaurant)
          end              
      end
      
    end

    # ========= Pages ====================

    #
    # Return the pages managed by the module
    # @return [Hash] Name - Url
    #
    def public_pages

      pages = {}
      pages.store(t.booking_pages.new_booking, '/p/booking/start')
      pages.store(t.booking_pages.booking_summary, '/p/booking/summary')

      return pages

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
    def page_script(context={}, page)
    
      ['/booking_js.js'] if ((defined?MY_BOOKING_FRONTEND) && (MY_BOOKING_FRONTEND == '3.0')) || (!defined?MY_BOOKING_FRONTEND) 
    
    end

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
    def ignore_path_prefix_language(context={})
      %w(/p/booking/payment-gateway /p/booking/pay /p/booking/summary /p/mybooking /p/activities/add-to-shopping-cart /p/activity/remove-to-shopping-cart /p/activities/shopping-cart /p/activities/shopping-cart-checkout)
    end

    #
    # Ignore the following path prefix in cms
    #
    def ignore_path_prefix_cms(context={})
      %w(/p/booking/payment-gateway /p/booking/pay /p/booking/summary /p/mybooking /p/activities/add-to-shopping-cart /p/activity/remove-to-shopping-cart /p/activities/shopping-cart /p/activities/shopping-cart-checkout)
    end

    #
    # Ignore the following path prefix in breadcrumb
    #
    def ignore_path_prefix_breadcrumb(context={})
      %w(/p/booking/payment-gateway /p/booking/pay /p/booking/summary /p/mybooking /p/activities/add-to-shopping-cart /p/activity/remove-to-shopping-cart /p/activities/shopping-cart /p/activities/shopping-cart-checkout)
    end

  end
end