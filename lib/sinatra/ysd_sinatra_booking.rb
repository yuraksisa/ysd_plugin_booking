require 'json' unless defined?JSON

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
            
        #
        # shows the booking page
        #
        app.get '/reserva/?' do
          load_page('reserva-online'.to_sym)
        end
           
        #
        # shows the booking page (extended for customers)
        #
        app.get '/reserva/:customer' do 
          load_page('reserva-online'.to_sym, :layout => "#{params[:customer]}-layout".to_sym)
        end   
            
        #
        # Creates a booking
        #
        app.post '/confirm_booking/?' do
              
          request.body.rewind 
          data = JSON.parse request.body.read     
  
          booking = BookingDataSystem::Booking.new data['booking'] 
          booking.save
    
          content_type :html
          "Request processed"

        end

        app.get '/booking/*' do

           serve_static_resource(request.path_info.gsub(/^\/booking/,''), File.join(File.dirname(__FILE__), '..', '..', 'static'), 'booking') 

        end
      
      end
      
    
    end # Booking
  end # YSD
end # Sinatra