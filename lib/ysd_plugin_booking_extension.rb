require 'ysd-plugins_viewlistener' unless defined?Plugins::ViewListener

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
            
    end
            
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
                 :module => :booking}             
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