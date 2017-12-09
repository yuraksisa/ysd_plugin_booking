require 'ysd_md_booking' unless defined?BookingDataSystem
require 'ysd_md_configuration' unless defined?SystemConfiguration

module Sinatra
  module YSD
    #
    # Sinatra extension to manage bookings
    #
    module Booking

      def self.registered(app) 
      
        app.settings.views = Array(app.settings.views).push(
          File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 
          'views')))
        app.settings.translations = Array(app.settings.translations).push(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'i18n')))      

      end
      
    end # Booking
  end # YSD
end # Sinatra