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
      
        app.set :bookingcharge_gateway_return_ok, '/reserva/payment-gateway-return/ok'
        app.set :bookingcharge_gateway_return_nok, '/reserva/payment-gateway-return/nok'

        #
        # It starts a booking process
        #
        app.get '/reserva/?' do
          load_page('reserva-online'.to_sym)
        end
           
        #
        # It returns from the payment gateway when the payment has been done
        #   
        app.get '/reserva/payment-gateway-return/ok' do
          if session.has_key?('booking_id')
            booking = BookingDataSystem::Booking.get(session['booking_id'])
            company = SystemConfiguration::Variable.get_value('site.company_name')
            load_page('reserva-finalizada'.to_sym, :locals => {:booking => booking,
              :company => company})
          else
            logger.error "Back from payment gateway NOT booking in session"
            status 404
          end
        end

        #
        # It returns from the payment gateway when the payment has been denied
        #
        app.get '/reserva/payment-gateway-return/nok' do
          if session.has_key?('booking_id')
            booking = BookingDataSystem::Booking.get(session['booking_id'])
            load_page('reserva-denegada'.to_sym, :locals => {:booking => booking})
          else
            logger.error "Back from payment gateway NOT booking in session"
            status 404
          end
        end
        
        #
        # It creates a charge to receive the booking deposit and process the
        # charge
        #
        # An booking_id has to be defined in the session in order to process
        # the charge
        # 
        app.get '/reserva/charge-deposit/?' do

          if session.has_key?('booking_id')
            booking = BookingDataSystem::Booking.get(session['booking_id'])
            charge = booking.create_deposit_charge!
            session[:charge_id] = charge.id
            status, header, body = call! env.merge("PATH_INFO" => "/charge", 
              "REQUEST_METHOD" => 'GET') 
          else
            status 404
          end

        end

        #
        # It starts a booking process (with a customer template)
        #
        app.get '/reserva/:customer' do 
          load_page('reserva-online'.to_sym, :layout => "#{params[:customer]}-layout".to_sym)
        end   
           
        #
        # Serves static content
        #
        app.get '/booking/*' do

           serve_static_resource(request.path_info.gsub(/^\/booking/,''), File.join(File.dirname(__FILE__), '..', '..', 'static'), 'booking') 

        end
      
      end
      
    end # Booking
  end # YSD
end # Sinatra