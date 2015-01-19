require 'ysd_md_configuration' unless defined?SystemConfiguration::Variable
require 'ysd_md_booking' unless defined?BookingDataSystem::Booking
require 'date'
module Sinatra
  module YSD
    
    module BookingManagementRESTApiHelper

      def booking_availability(params)

        if params['from'].nil? or params['to'].nil?
           []
        else
           begin
             from = DateTime.strptime(params[:from], '%Y-%m-%d')
             to = DateTime.strptime(params[:to], '%Y-%m-%d')
             ::Yito::Model::Booking::Availability.instance.categories_available(from, to)
           rescue ArgumentError => ex
             []
           end
        end  

      end

      def booking_payment_enabled(params)

        if params['from'].nil? or params['to'].nil?
          []
        else
          begin
            from = DateTime.strptime(params[:from], '%Y-%m-%d')
            if (BookingDataSystem::Booking.payment_cadence?(from))
              to = DateTime.strptime(params[:to], '%Y-%m-%d')
              ::Yito::Model::Booking::Availability.instance.categories_payment_enabled(from, to)
            else
              []
            end
          rescue ArgumentError => ex
              []
          end
        end  
        
      end

    end

  	module BookingManagementRESTApi
      
      def self.registered(app)

        #
        # Check availability and payment
        #
        app.get '/api/booking/check' do
         
          result = {:availability => booking_availability(params),
                    :payment => booking_payment_enabled(params)}
          result.to_json          

        end

        #
        # Check availability
        #        
        app.get '/api/booking/availability' do

          cats = booking_availability(params)
          cats.to_json

        end

        #
        # Check the categories that have payment enabled
        #
        app.get '/api/booking/payment-enabled' do

          cats = booking_payment_enabled(params)
          cats.to_json
        
        end

        #
        # Booking statistics
        #
        app.get '/api/booking/statistics', :allowed_usergroups => ['booking_manager', 'staff']  do

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

        #
        # Incoming money
        #
        app.get '/api/booking/incoming-money', :allowed_usergroups => ['booking_manager', 'staff']  do

          data = BookingDataSystem::Booking.incoming_money_summary

          result = {}

          data.each do |item|
            result.store(item.period, :total => sprintf("%.2f", item.total))
          end

          result.to_json

        end 

        #
        # Bookings scheduler
        #
        app.get '/api/booking/scheduler/:booking_item_reference', :allowed_usergroups => ['booking_manager', 'staff'] do

          from = Time.at(params['start'].to_i)
          to = Time.at(params['end'].to_i)

          condition = Conditions::JoinComparison.new('$and',
           [Conditions::Comparison.new(:status, '$ne', :cancelled),
            Conditions::Comparison.new(:booking_item_reference, '$eq', params[:booking_item_reference]),
            Conditions::JoinComparison.new('$or', 
              [Conditions::JoinComparison.new('$and', 
                 [Conditions::Comparison.new(:date_from,'$lte', from),
                  Conditions::Comparison.new(:date_to,'$gte', from)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new(:date_from,'$lte', to),
                  Conditions::Comparison.new(:date_to,'$gte', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new(:date_from,'$eq', from),
                  Conditions::Comparison.new(:date_to,'$eq', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new(:date_from, '$gte', from),
                  Conditions::Comparison.new(:date_to, '$lte', to)])               
              ]
            ),
            ]
          )

          bookings = condition.build_datamapper(BookingDataSystem::Booking).all(
             :order => [:item_id.asc]).map do |booking|
            {:id => booking.id,
             :title => "#ID: #{booking.id} \n #{booking.date_from.strftime('%Y-%m-%d')} #{booking.time_from} \n #{booking.date_to.strftime('%Y-%m-%d')} #{booking.time_to} \n #{booking.customer_name.upcase} #{booking.customer_surname.upcase} #{(booking.customer_phone.nil? or booking.customer_phone.empty?)? booking.customer_mobile_phone : booking.customer_phone}",
             :start => booking.date_from,
             :end => booking.date_to,
             :url => "/admin/booking/bookings/#{booking.id}",
             :editable => false,
             :backgroundColor => (booking.status==:confirmed)? 'rgb(41, 158, 69)' : (booking.status==:in_progress)? 'rgb(13, 124, 226)' : (booking.status == :pending_confirmation)? 'rgb(241, 248, 69)' : 'rgb(0,0,0)',
             :textColor => (booking.status == :pending_confirmation)? 'black' : 'white'}
          end

          bookings.to_json

        end

        #
        # Bookings (planning)
        #
        app.get '/api/booking/planning', :allowed_usergroups => ['booking_manager', 'staff'] do

          today = DateTime.now
          month = today.month
          year = today.year

          if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
            month = params[:month].to_i
          end
           
          if params[:year]
            year = params[:year].to_i
          end

          from = DateTime.new(year, month, 1, 0, 0, 0, 0)
          to = from >> 1

          condition = Conditions::JoinComparison.new('$and',
           [Conditions::Comparison.new(:status, '$eq', :confirmed),
            Conditions::Comparison.new(:booking_item, '$ne', nil),
            Conditions::JoinComparison.new('$or', 
              [Conditions::JoinComparison.new('$and', 
                 [Conditions::Comparison.new(:date_from,'$lte', from),
                  Conditions::Comparison.new(:date_to,'$gte', from)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new(:date_from,'$lte', to),
                  Conditions::Comparison.new(:date_to,'$gte', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new(:date_from,'$eq', from),
                  Conditions::Comparison.new(:date_to,'$eq', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new(:date_from, '$gte', from),
                  Conditions::Comparison.new(:date_to, '$lte', to)])               
              ]
            ),
            ]
          )

          bookings = condition.build_datamapper(BookingDataSystem::Booking).all(
             :fields => [:id, :date_from, :date_to, :booking_item_reference],
             :order => [:booking_item_reference.asc, :date_from.asc]
            ) 

          bookings.to_json(:only => [:id, :date_from, :date_to, :booking_item_reference])

        end


        #
        # Regenerates the booking_js template
        #
        app.post '/api/booking/create-rates', :allowed_usergroups => ['booking_manager', 'staff']  do
  
          rates = ::Yito::Model::Booking::Generator.instance.build_script

          if booking_js=ContentManagerSystem::Template.find_by_name('booking_js')
             booking_js.text = rates
             booking_js.save
          else
             ContentManagerSystem::Template.create({:name => 'booking_js', 
                :description => 'Definición de los productos en alquiler y las tarifas',
                :text => rates})
          end

          rates

        end
        #
        # Get the items that have to be pick up
        #
        app.get '/api/booking/pickedup', :allowed_usergroups => ['booking_manager', 'staff'] do

           from = DateTime.now
           if params[:from]
             from = DateTime.strptime(params[:from], '%Y-%m-%d')
           end

           to = from
           if params[:to]
             to = DateTime.strptime(params[:to], '%Y-%m-%d')
           end

           data = BookingDataSystem::Booking.all(
            :date_from.gte => from,
            :date_from.lte => to,
            :status => [:confirmed, :in_progress, :done],
            :order => [:date_from.asc, :time_from.asc])

           data.to_json

        end

        #
        # Get the items that have to be returned
        #
        app.get '/api/booking/returned', :allowed_usergroups => ['booking_manager', 'staff'] do

           from = DateTime.now
           if params[:from]
             from = DateTime.strptime(params[:from], '%Y-%m-%d')
           end

           to = from
           if params[:to]
             to = DateTime.strptime(params[:to], '%Y-%m-%d')
           end

           data = BookingDataSystem::Booking.all(
            :date_to.gte => from,
            :date_to.lte => to,
            :status => [:confirmed, :in_progress, :done],
            :order => [:date_to.asc, :time_to.asc])

           data.to_json

        end

        #
        # Get the not assigned bookings
        #
        app.get '/api/booking/not-assigned', :allowed_usergroups => ['booking_manager', 'staff'] do

          from = params['start']
          to = params['end']

          bookings = BookingDataSystem::Booking.all(
             :date_from.gte => Time.at(from.to_i),
             :date_to.lte => Time.at(to.to_i), 
             #:status => [:confirmed],
             #:booking_item => nil,
             :order => [:item_id.asc]
            )

          bookings.to_json

        end

        #
        # Booking querying 
        #
        ["/api/bookings", "/api/bookings/page/:page"].each do |path|
          app.post path, :allowed_usergroups => ['booking_manager', 'staff'] do
        	
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
        app.get '/api/booking/:booking_id',
          :allowed_usergroups => ['booking_manager','staff'] do

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
        app.post '/api/booking/confirm/:booking_id',
          :allowed_usergroups => ['booking_manager','staff'] do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            content_type :json
            booking.confirm!.to_json
          else
            status 404
          end

        end

        #
        # Allow payment
        #
        app.post '/api/booking/allow-payment/:booking_id', 
          :allowed_usergroups => ['booking_manager', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            booking.force_allow_payment = true
            booking.save
            content_type :json
            booking.to_json
          else
            status 404
          end

        end

        #
        # Assign a booking item to a booking
        #
        app.post '/api/booking/assign/:booking_id/:booking_item_reference',
          :allowed_usergroups => ['booking_manager','staff'] do

          if booking = BookingDataSystem::Booking.get(params[:booking_id].to_i)
            if booking_item = ::Yito::Model::Booking::BookingItem.get(params[:booking_item_reference])
              booking.booking_item = booking_item
              booking.save
              content_type :json
              booking.to_json
            else
              status 404
            end  
          else
            status 404
          end 

        end

        #
        # Pickup/Arrival 
        #
        app.post '/api/booking/pickup/:booking_id',
          :allowed_usergroups => ['booking_manager','staff']  do
       
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
        app.post '/api/booking/return/:booking_id',
          :allowed_usergroups => ['booking_manager','staff']  do

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
        app.post '/api/booking/cancel/:booking_id',
          :allowed_usergroups => ['booking_manager','staff']  do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            content_type :json
            booking.cancel.to_json
          else
            status 404
          end

        end

        #
        # Update the booking price
        #
        app.put '/api/booking/:id/price', :allowed_usergroups => ['booking_manager','staff'] do

          booking_request = body_as_json(BookingDataSystem::Booking)
          extras_request = booking_request.delete(:booking_extras)
 
          booking = BookingDataSystem::Booking.get(params[:id])
          booking.transaction do |transaction|
            booking.attributes = booking_request
            booking.save
            extras_request.each do |extra_booking|
              booking_extra = BookingDataSystem::BookingExtra.get(extra_booking[:id])
              booking_extra.extra_cost = extra_booking[:extra_cost]
              booking_extra.extra_unit_cost = extra_booking[:extra_unit_cost]
              booking_extra.save
            end
            transaction.commit
          end

        end

        #
        # Updates booking
        #
        app.put '/api/booking/:id', :allowed_usergroups => ['booking_manager','staff']  do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys! 

          if booking = BookingDataSystem::Booking.get(params[:id])
            booking.attributes = data
            booking.save
            body booking.to_json
          else
            status 404
          end
          

        end

        #
        # Update booking
        #
        app.put '/api/booking', :allowed_usergroups => ['booking_manager', 'staff'] do

          data_request = body_as_json(BookingDataSystem::Booking)
                              
          if data = BookingDataSystem::Booking.get(data_request.delete(:id).to_i)     
            data.attributes=data_request  
            data.save
          end
      
          content_type :json
          data.to_json        

        end

        #
        # Booking creation (customer)
        #
        app.post '/api/booking/?' do

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

        #
        # Booking creation (manager)
        #
        app.post '/api/booking-from-manager/?', :allowed_usergroups => ['booking_manager', 'staff'] do

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
          booking.created_by_manager = true
          booking.save

          session[:booking_id] = booking.id
          
          # Pay booking
          response =  <<-HTML
                         <script type="text/javascript">
                         window.location.href= "/admin/bookings"
                         </script>
                       HTML
          
          status 200
          body response

        end
      
      end

    end #BookingManagementRESTApi
  end #YSD
end #Sinatra