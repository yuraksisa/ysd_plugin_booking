require 'ysd-plugins_viewlistener' unless defined?Plugins::ViewListener
require 'ysd_md_configuration' unless defined?SystemConfiguration::Variable
require 'ysd_md_cms' unless defined?ContentManagerSystem::Template
require 'ysd_md_booking' unless defined?Yito::Model::Booking::ProductFamily

#
# Huasi CMS Extension
#
module Huasi
  class BookingExtension < Plugins::ViewListener

    # ========= Installation =================

    # 
    # Install the plugin
    #
    def install(context={})

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
        {:name => 'booking.season_definition.id'},
        {:value => '0',
         :description => 'Default season definition',
         :module => :booking})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.factor_definition.id'},
        {:value => '0',
         :description => 'Default factor definition',
         :module => :booking})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'booking.allow_custom_pickup_return_place'},
        {:value => 'false',
         :description => 'Allow custom pickup and return places'})

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

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'place'},
        {:driver => false,
         :guests => true,
         :flight => true,
         :pickup_return_place => false,
         :time_to_from => false,
         :start_date_literal => :arrival} )

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'car'},
        {:driver => true,
         :guests => false,
         :flight => true,
         :pickup_return_place => true,
         :time_to_from => true,
         :start_date_literal => :pickup} )

      Yito::Model::Booking::ProductFamily.first_or_create({:code => 'bike'},
        {:driver => false,
         :guests => false,
         :flight => false,
         :pickup_return_place => false,
         :time_to_from => true,
         :start_date_literal => :pickup} )

      if Yito::Model::Calendar::EventType.count(:name => 'not_available') == 0
        Yito::Model::Calendar::EventType.create(:name => 'not_available', 
          :description => 'Not available')
      end

      if Yito::Model::Calendar::EventType.count(:name => 'payment_enabled') == 0
        Yito::Model::Calendar::EventType.create(:name => 'payment_enabled', 
          :description => 'Payment enabled')
      end

      Users::Group.first_or_create({:group => 'booking_manager'},
          {:name => 'Booking manager', :description => 'Booking manager'})

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

      if booking_js=ContentManagerSystem::Template.find_by_name('booking_js') and 
         not booking_js.text.empty?
        locals.store(:booking_js, booking_js.text) 
      end      

      case block_name
        when 'booking_selector'    
          app.partial(:booking_selector, :locals => locals)
        when 'booking_selector_inline'         
          app.partial(:booking_selector_inline, :locals => locals)          
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

      return pages

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
    
  end
end