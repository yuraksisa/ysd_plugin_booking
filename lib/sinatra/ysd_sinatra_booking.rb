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
      
        app.set :bookingcharge_gateway_return_ok, '/p/booking/payment-gateway-return/ok'
        app.set :bookingcharge_gateway_return_cancel, '/p/booking/payment-gateway-return/cancel'
        app.set :bookingcharge_gateway_return_nok, '/p/booking/payment-gateway-return/nok'
        
        #
        # Shows a booking: To be managed by the customer
        #   
        app.get '/p/mybooking/:id' do
          if booking = BookingDataSystem::Booking.get_by_free_access_id(params[:id])
            locals = {:booking => booking}
            locals.store(:booking_deposit,
              SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i)            
            locals.store(:booking_payment,
              SystemConfiguration::Variable.get_value('booking.payment', 'false').to_bool)
            load_page :reserva, :locals => locals
          else
            status 404
          end
        end

        #
        # It starts a booking process
        #
        app.get '/p/booking/start/?' do          
          
          options = {}

          options.store(:page_title,
            SystemConfiguration::Variable.get_value('booking.page_title'))

          options.store(:page_description,
            SystemConfiguration::Variable.get_value('booking.page_description'))

          options.store(:page_language, session[:locale])

          options.store(:page_keywords,
            SystemConfiguration::Variable.get_value('booking.page_keywords'))          

          options.store(:layout, params['layout']=='false'? false : params['layout']) if params.has_key?('layout')

          locals = {}

          locals.store(:booking_item_family, 
            ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))

          locals.store(:booking_item_type,
            SystemConfiguration::Variable.get_value('booking.item_type'))
       
          locals.store(:booking_payment,
            SystemConfiguration::Variable.get_value('booking.payment', 'false').to_bool)

          locals.store(:booking_deposit,
            SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i)

          locals.store(:booking_min_days,
            SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i)

          locals.store(:booking_allow_custom_pickup_return_place,
            SystemConfiguration::Variable.get_value('booking.allow_custom_pickup_return_place', 'false').to_bool)

          if booking_js=ContentManagerSystem::Template.find_by_name('booking_js') and 
             not booking_js.text.empty?
            locals.store(:booking_js, booking_js.text) 
          end
          
          if summary_message=ContentManagerSystem::Template.find_by_name('booking_summary_message') and
             not summary_message.text.empty?
            locals.store(:booking_summary_message, summary_message.text)
          else
            locals.store(:booking_summary_message, t.new_booking.summary_message)
          end
                 
          load_page('reserva-online'.to_sym, options.merge(:locals => locals))
        end
        
        #
        # Booking summary (booking request)
        #
        app.get '/p/booking/summary/?' do

          if session[:booking_id]
            booking = BookingDataSystem::Booking.get(session[:booking_id])
            locals = {:booking => booking}
            if summary_message=ContentManagerSystem::Template.find_by_name('booking_summary_message') and
              not summary_message.text.empty?
              template = ERB.new summary_message.text     
              message = template.result(binding)
              locals.store(:booking_summary_message, message)
            else
              locals.store(:booking_summary_message, t.new_booking.summary_message)
            end
            load_page :reserva_request, :locals => locals
          else
             status 404
          end

        end

        #
        # Integration in facebook as a tab
        #
        app.post '/p/booking/start/?' do
          status, header, body = call! env.merge("PATH_INFO" => "/p/booking/start", 
                "REQUEST_METHOD" => 'GET')
        end

        #
        # Register a deposit payment on the booking 
        #
        app.post '/p/booking/pay/?', 
          :allowed_origin => lambda { SystemConfiguration::Variable.get_value('site.domain') } do
          
          if booking = BookingDataSystem::Booking.get(params[:id].to_i)
            payment = params[:payment]
            payment_method = params[:payment_method_id]
            if charge = booking.create_online_charge!(payment, payment_method)
              session[:booking_id] = booking.id
              session[:charge_id] = charge.id
              status, header, body = call! env.merge("PATH_INFO" => "/charge", 
                "REQUEST_METHOD" => 'GET')
            else
              redirect "/p/mybooking/#{booking.free_access_id}"
            end            
          else
            status 404
          end 

        end

        #
        # It returns from the payment gateway when the payment has been done
        # 
        # Notifies to the user that the reservation has finished
        #   
        app.get '/p/booking/payment-gateway-return/ok' do

          if session[:charge_id]
            booking = BookingDataSystem::BookingCharge.booking_from_charge(session[:charge_id])
            locals = {}
            locals.store(:booking, booking)
            locals.store(:booking_deposit, SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i)
            load_page('reserva-finalizada'.to_sym, :locals => locals)
          else
            logger.error "Back from payment gateway NOT booking in session"
            status 404
          end
        end

        #
        # It returns from the payment gateway when the user returns or cancel
        #
        # Shows the reservation information
        #
        app.get '/p/booking/payment-gateway-return/cancel' do

          if session[:charge_id]
             booking = BookingDataSystem::BookingCharge.booking_from_charge(session[:charge_id])
             locals = {:booking => booking}
             locals.store(:booking_deposit, 
                 SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i)            
             locals.store(:booking_payment,
                 SystemConfiguration::Variable.get_value('booking.payment', 'false').to_bool)
             load_page :reserva, :locals => locals
          else
             logger.error "Back from payment gateway NOT booking in session"
             status 404
          end
        end

        #
        # It returns from the payment gateway when the payment has been denied
        #
        # Shows the reservation payment denied
        #
        app.get '/p/booking/payment-gateway-return/nok' do
          if session[:charge_id]
            booking = BookingDataSystem::BookingCharge.booking_from_charge(session[:charge_id])
            locals = {}
            locals.store(:booking, booking)
            locals.store(:booking_deposit, SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i)
            load_page('reserva-denegada'.to_sym, :locals => locals)
          else
            logger.error "Back from payment gateway NOT booking in session"
            status 404
          end
        end
                
        #
        # It starts a booking process (with a customer template)
        #
        app.get '/p/booking/:customer' do 
          pass unless get_path("#{params[:customer]}-layout}")
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