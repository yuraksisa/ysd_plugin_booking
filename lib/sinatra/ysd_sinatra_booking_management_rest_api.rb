require 'ysd_md_configuration' unless defined?SystemConfiguration::Variable
require 'ysd_md_booking' unless defined?BookingDataSystem::Booking
module Sinatra
  module YSD
  	module BookingManagementRESTApi
      
      def self.registered(app)
        
        app.get '/booking/statistics', :allowed_usergroups => ['booking_manager', 'staff']  do

          received = BookingDataSystem::Booking.reservations_received
          confirmed = BookingDataSystem::Booking.reservations_confirmed
          
          result = {}

          received.each do |item|
            result.store(item.period, :requests => item.occurrences, :confirmed => 0)
          end
          
          confirmed.each do |item|
            result.fetch(item.period).store(:confirmed, item.occurrences)
          end

          result.to_json

        end

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
             :textColor => (booking.status == :pending_confirmation)? 'black' : 'white'}
          end

          bookings.to_json

        end

        #
        # Booking querying 
        #
        ["/bookings", "/bookings/page/:page"].each do |path|
          app.post path, :allowed_usergroups => ['booking_manager'] do
        	
            page = [params[:page].to_i, 1].max  
            page_size = SystemConfiguration::Variable.
              get_value('configuration.booking_page_size', 20).to_i
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:creation_date.desc]} 

            if request.media_type == "application/x-www-form-urlencoded"
              search_text = if params[:search]
                              params[:search]
                            else
                              request.body.rewind
                              request.body.read
                            end
              conditions = Conditions::JoinComparison.new('$or', 
                              [Conditions::Comparison.new(:id, '$eq', search_text.to_i),
                               Conditions::Comparison.new(:customer_surname, '$like', "%#{search_text}%"),
                               Conditions::Comparison.new(:customer_email, '$eq', search_text)])
            
              total = conditions.build_datamapper(BookingDataSystem::Booking).all.count 
              data = conditions.build_datamapper(BookingDataSystem::Booking).all(offset_order_query) 
            else
              data, total = BookingDataSystem::Booking.all_and_count(offset_order_query)
            end

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

          options = extract_request_query_string
              
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

          session[:booking_id] = booking.id
          
          # Pay booking
          response = if booking.pay_now
                       <<-HTML
                         <script type="text/javascript">
                         window.location.href= "/p/mybooking/#{booking.free_access_id}"
                         </script>
                       HTML
                     else
                       <<-HTML
                         <script type="text/javascript">
                         window.location.href= "/p/booking/summary"
                         </script>
                       HTML
                     end
          
          status 200
          body response

        end

      end

    end #BookingManagementRESTApi
  end #YSD
end #Sinatra