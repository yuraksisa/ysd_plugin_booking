require 'ysd-plugins_viewlistener' unless defined?Plugins::ViewListener
require 'ysd_md_configuration' unless defined?SystemConfiguration::Variable

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
                                  :weight => 2}
                    },
                    {:path => '/apps/bookings/bookings',              
                     :options => {:title => app.t.system_admin_menu.apps.bookings_menu.bookings,
                                  :link_route => "/admin/bookings",
                                  :description => 'Booking charges',
                                  :module => :booking,
                                  :weight => 2}
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
                {:path => '/apps/bookings/bookings',
                 :regular_expression => /^\/admin\/bookings/, 
                 :title => 'Bookings', 
                 :description => 'Booking management',
                 :fit => 1,
                 :module => :booking }                              
               ]
        
    end
    
    #
    # It gets the style sheets defined in the module
    #
    # @param [Context]
    #
    # @return [Array]
    #   An array which contains the css resources used by the module
    #
    #def page_style(context={})
    #  [
    #    '/booking/css/booking.css'         
    #  ]       
    #end

  end
end