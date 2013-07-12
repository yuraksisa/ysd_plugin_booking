require 'ysd_md_configuration' unless defined?SystemConfiguration::Variable
require 'ysd_md_booking' unless defined?BookingDataSystem::Booking
module Sinatra
  module YSD
  	module BookingManagementRESTApi
      
      def self.registered(app)
        
        # Booking scheduler
        app.get '/booking/scheduler' do

          from = params['start']
          to = params['end']

          bookings = BookingDataSystem::Booking.all(
             :date_from.gte => Time.at(from.to_i),
             :date_to.lte => Time.at(to.to_i), 
             :status.not => :cancelled,
             :order => [:item_id.asc]).map do |booking|
            {:id => booking.id,
             :title => "#{booking.item_description} - #{booking.customer_name.upcase} #{booking.customer_surname.upcase} #{(booking.customer_phone.nil? or booking.customer_phone.empty?)? booking.customer_mobile_phone : booking.customer_phone}",
             :start => booking.date_from,
             :end => booking.date_to,
             :url => "/admin/bookings/#{booking.id}",
             :editable => false,
             :backgroundColor => (booking.status==:confirmed)? 'rgb(41, 158, 69)' : (booking.status==:in_progress)? 'rgb(13, 124, 226)' : (booking.status == :pending_confirmation)? 'rgb(241, 248, 69)' : 'rgb(0,0,0)',
             :textColor => 'white'}
          end

          bookings.to_json

        end

        #
        # Booking querying 
        #
        ["/bookings", "/bookings/page/:page"].each do |path|
          app.post path, :allowed_usergroups => ['booking_manager'] do
        	
            query_options = {}
            if request.media_type == "application/x-www-form-urlencoded"
              if params[:search]
                query_options[:conditions] = {:id => params[:search]} 
              else
                request.body.rewind
                search_text=request.body.read
                query_options[:conditions] = {:id => search_text} 
              end
            end
            page_size = SystemConfiguration::Variable.
              get_value('configuration.booking_page_size', 20).to_i 
            page = [params[:page].to_i, 1].max  
            data, total = BookingDataSystem::Booking.all_and_count(
              query_options.merge({:offset => (page - 1)  * page_size, :limit => page_size, :order => [:creation_date.desc]}) )
            content_type :json
            {:data => data, :summary => {:total => total}}.to_json

          end
        end

        #
        # Booking access
        #
        app.get '/booking/:booking_id',
          :allowed_usergroups => ['booking_manager'] do

          if booking=BookingDataSystem::Booking.get(params[:booking_id])
            status 200
            booking.to_json
          else
            status 404
          end

        end
        
        #
        # Confirm a booking
        #
        app.post '/booking/confirm/:booking_id',
          :allowed_usergroups => ['booking_manager'] do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            content_type :json
            booking.confirm!.to_json
          else
            status 404
          end

        end

        #
        # Pickup/Arrival 
        #
        app.post '/booking/pickup/:booking_id',
          :allowed_usergroups => ['booking_manager']  do
       
          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            content_type :json
            booking.pickup_item.to_json
          else
            status 404
          end
    
        end

        #
        # Return/Departure
        #
        app.post '/booking/return/:booking_id',
          :allowed_usergroups => ['booking_manager']  do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            content_type :json
            booking.return_item.to_json
          else
            status 404
          end

        end

        #
        # Cancel
        #
        app.post '/booking/cancel/:booking_id',
          :allowed_usergroups => ['booking_manager']  do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            content_type :json
            booking.cancel.to_json
          else
            status 404
          end

        end

        #
        # Booking creation
        #
        app.post '/booking/?' do
              
          request.body.rewind 
          data = JSON.parse request.body.read     
          
          booking_data = data['booking'].keep_if do |key, value| 
            BookingDataSystem::Booking.properties.field_map.keys.include?(key) or 
            BookingDataSystem::Booking.relationships.named?(key)
          end
          booking_data.symbolize_keys!
          unless booking_data.has_key?(:customer_language)
            booking_data[:customer_language] = session[:locale] || 'es'
          end

          booking = BookingDataSystem::Booking.new(booking_data)
          booking.save
          
          if not booking.charges.empty?
            session[:booking_id] = booking.id
            session[:charge_id] = booking.charges.first.id
            status, header, body = call! env.merge("PATH_INFO" => "/charge", 
              "REQUEST_METHOD" => 'GET') 
          else
            content_type :json
            booking.to_json
          end

        end


      end

    end #BookingManagementRESTApi
  end #YSD
end #Sinatra