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

      def booking_stock

         ::Yito::Model::Booking::BookingCategory.all(:conditions => {:active => true}, :fields => [:code, :stock_control, :stock]).map do |item| 
           {item_id: item.code, stock_control: item.stock_control, stock: item.stock}
         end

      end

      def booking_occupation(params)

        if params['from'].nil? or params['to'].nil?
           []
        else
           begin
             from = DateTime.strptime(params[:from], '%Y-%m-%d')
             to = DateTime.strptime(params[:to], '%Y-%m-%d')
             BookingDataSystem::Booking.occupation(from, to).map do |item|  
                {item_id: item.item_id, stock: item.stock, busy: item.busy}
             end
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

      def booking_planning_conditions(params)
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
            #Conditions::Comparison.new(:booking_item, '$ne', nil),
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
      end

      def booking_confirmed_conditions(params)
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
      end

    end

  	module BookingManagementRESTApi
      
      def self.registered(app)

        #
        # Check availability and payment
        #
        app.get '/api/booking/check' do
         
          occupation_hash=booking_occupation(params).inject({}) do |result,item| 
             result.store(item[:item_id], item.select {|key,value| key != :item_id}) 
             result 
          end

          stock_hash=booking_stock.inject({}) do |result,item| 
             result.store(item[:item_id], item.select { |key,value| key != :item_id})
             result
          end
          
          stock_hash.each do |key, value|
             if occupation_hash.has_key?(key) 
               value.store(:busy, occupation_hash[key][:busy])
             else
               value.store(:busy, 0)
             end
          end

          availables = booking_availability(params)

          availability = availables.select do |item| 
                           true if stock_hash.has_key?(item) and ((stock_hash[item][:stock_control] and stock_hash[item][:busy] < stock_hash[item][:stock]) or (!stock_hash[item][:stock_control]))
                         end

          result = {:availability => availability,
                    :payment => booking_payment_enabled(params),
                    :stock => stock_hash}
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

          year = params[:year] || Date.today.year

          received = BookingDataSystem::Booking.reservations_received(year)
          confirmed = BookingDataSystem::Booking.reservations_confirmed(year)
          
          result = {}

          (1..12).each do |element| 
            period = "#{year}-#{element.to_s.rjust(2, '0')}"
            result.store(period, {requests: 0, confirmed: 0})
          end          

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

          year = params[:year] || Date.today.year

          data = BookingDataSystem::Booking.incoming_money_summary(year)

          result = {}

          (1..12).each do |element| 
            period = "#{year}-#{element.to_s.rjust(2, '0')}"
            result.store(period, {total: 0})
          end  

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
           [Conditions::Comparison.new('booking_line.booking.status', '$ne', :cancelled),
            Conditions::Comparison.new(:booking_item_reference, '$eq', params[:booking_item_reference]),
            Conditions::JoinComparison.new('$or', 
              [Conditions::JoinComparison.new('$and', 
                 [Conditions::Comparison.new('booking_line.booking.date_from','$lte', from),
                  Conditions::Comparison.new('booking_line.booking.date_to','$gte', from)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from','$lte', to),
                  Conditions::Comparison.new('booking_line.booking.date_to','$gte', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from','$eq', from),
                  Conditions::Comparison.new('booking_line.booking.date_to','$eq', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from', '$gte', from),
                  Conditions::Comparison.new('booking_line.booking.date_to', '$lte', to)])               
              ]
            ),
            ]
          )

          bookings = condition.build_datamapper(BookingDataSystem::BookingLineResource).all(
             ).map do |booking_line_resource|
            booking = booking_line_resource.booking_line.booking
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
        # Bookings scheduler
        #
        app.get '/api/booking/scheduler', :allowed_usergroups => ['booking_manager', 'staff'] do

          from = Time.at(params['start'].to_i)
          to = Time.at(params['end'].to_i)

          condition = Conditions::JoinComparison.new('$and',
           [Conditions::Comparison.new('booking_line.booking.status', '$ne', :cancelled),
            Conditions::JoinComparison.new('$or', 
              [Conditions::JoinComparison.new('$and', 
                 [Conditions::Comparison.new('booking_line.booking.date_from','$lte', from),
                  Conditions::Comparison.new('booking_line.booking.date_to','$gte', from)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from','$lte', to),
                  Conditions::Comparison.new('booking_line.booking.date_to','$gte', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from','$eq', from),
                  Conditions::Comparison.new('booking_line.booking.date_to','$eq', to)
                  ]),
               Conditions::JoinComparison.new('$and',
                 [Conditions::Comparison.new('booking_line.booking.date_from', '$gte', from),
                  Conditions::Comparison.new('booking_line.booking.date_to', '$lte', to)])               
              ]
            ),
            ]
          )

          bookings = condition.build_datamapper(BookingDataSystem::BookingLineResource).all(
             ).map do |booking_line_resource|
            booking = booking_line_resource.booking_line.booking
            start_str = "#{booking.date_from.strftime('%Y-%m-%d')}T#{booking.time_from}:00"
            end_str = "#{booking.date_to.strftime('%Y-%m-%d')}T#{booking.time_to}:00"
            {:id => booking.id,
             :title => "#ID: #{booking.id} \n #{booking.customer_name.upcase} #{booking.customer_surname.upcase} (#{booking.number_of_adults}) \n #{(booking.customer_phone.nil? or booking.customer_phone.empty?)? booking.customer_mobile_phone : booking.customer_phone}",
             :start => start_str,
             :end => end_str,
             :allDay => false,
             :url => "/admin/simple/booking/bookings/#{booking.id}",
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

          condition = booking_planning_conditions(params)

          bookings = condition.build_datamapper(BookingDataSystem::Booking).all(
             :order => [:date_from.asc]
            ) 

          bookings.to_json(:only => [:id, :date_from, :date_to, :planning_color],
                           :relationships => {:booking_line_resources => {}})

        end

        #
        # Get the confirmed bookings that have not been assigned
        #
        # Params
        #
        # @param [month]
        # @param [year]
        #
        app.get '/api/booking/confirmed', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          condition = booking_confirmed_conditions(params)

          bookings = condition.build_datamapper(BookingDataSystem::Booking).all(
             :order => [:date_from.asc]
            )

          bookings.to_json(:only => [:id, :date_from, :date_to, :customer_name, :customer_surname,
              :customer_phone, :customer_mobile_phone, :status, :planning_color], 
                           :relationships => {:booking_line_resources => {}})

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
        # Regenerates the booking_js template
        #
        app.post '/api/booking/create-rates', :allowed_usergroups => ['booking_manager', 'staff']  do
  
          ::Yito::Model::Booking::Generator.instance.create_rates

          true.to_json
          
        end        

        # ---------------------------------------------------------------

        #
        # Booking querying 
        #
        ["/api/bookings", "/api/bookings/page/:page"].each do |path|
          app.post path, :allowed_usergroups => ['booking_manager', 'staff'] do
        	
            page = [params[:page].to_i, 1].max  
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:creation_date.desc]} 

            if request.media_type == "application/x-www-form-urlencoded"
              search_text = if params[:search]
                              params[:search]
                            else
                              request.body.rewind
                              request.body.read
                            end
              total, data = BookingDataSystem::Booking.text_search(search_text,offset_order_query)
            else
              data, total = BookingDataSystem::Booking.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json

          end
        end

        #
        # Main booking search
        #
        app.get '/api/bookings/main-search/:id/?*', :allowed_usergroups => ['booking_manager', 'staff'] do
          search_text = params[:term]
          
          conditions =  Conditions::JoinComparison.new('$and',
                        [ Conditions::Comparison.new(:id, '$ne', params[:id]),
                          Conditions::Comparison.new(:main_booking_id, '$eq', nil),
                          Conditions::JoinComparison.new('$or', 
                             [Conditions::Comparison.new(:id, '$eq', search_text.to_i),
                              Conditions::Comparison.new(:customer_name, '$like', "%#{search_text}%"),
                              Conditions::Comparison.new(:customer_surname, '$like', "%#{search_text}%"),
                              Conditions::Comparison.new(:customer_email, '$eq', search_text)
                             ])
                        ])

          data = conditions.build_datamapper(BookingDataSystem::Booking).all.map do |booking|
            {:value => booking.id,
             :label => "#{booking.id} - #{booking.date_from.strftime('%Y-%m-%d')} - #{booking.date_to.strftime('%Y-%m-%d')} - #{booking.customer_name.upcase} #{booking.customer_surname.upcase} "
            } 
          end
          data.to_json

        end
        
        #
        # Get the reservations that linked to this one
        #
        app.get '/api/bookings/linked/:id/?*', :allowed_usergroups => ['booking_manager', 'staff'] do

          result = if booking = BookingDataSystem::Booking.get(params[:id])
                     conditions = if booking.main_booking 
                                    Conditions::JoinComparison.new('$or', [
                                      Conditions::Comparison.new(:main_booking_id, '$eq', booking.main_booking.id),
                                      Conditions::Comparison.new(:id, '$eq', booking.main_booking.id)])
                                  else
                                    Conditions::JoinComparison.new('$or', [
                                      Conditions::Comparison.new(:main_booking_id, '$eq', booking.id),
                                      Conditions::Comparison.new(:id, '$eq', booking.id)
                                      ])
                                  end   
                     conditions.build_datamapper(BookingDataSystem::Booking).all.map do |booking|
                        {:id => booking.id,
                         :customer_name => booking.customer_name,
                         :customer_surname => booking.customer_surname,
                         :date_from => booking.date_from,
                         :time_from => booking.time_from,
                         :date_to => booking.date_to,
                         :time_to => booking.time_to,
                         :main_booking_id => booking.main_booking_id,
                         :status => booking.status,
                         :detail => booking.booking_lines.inject("") { |result, item| result + "#{item.quantity}-#{item.item_id} " }.strip
                         }
                     end
                   else
                     []
                   end

          result.to_json

        end

        #
        # Unlink a booking
        # 
        app.post '/api/booking/unlink/:booking_id', :allowed_usergroups => ['booking_manager', 'staff'] do

          if booking = BookingDataSystem::Booking.get(params[:booking_id])
            booking.main_booking = nil
            booking.save
            content_type :json
            status 200
            booking.to_json
          else
            status 404
          end

        end

        #
        # Register a booking charge
        #
        app.post '/api/booking/charge', :allowed_usergroups => ['bookings_manager','staff'] do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys! 

          if booking = BookingDataSystem::Booking.get(data[:id])
            
            booking.transaction do  
              charge = Payments::Charge.new
              charge.date = data[:date]
              charge.amount = data[:amount]
              charge.payment_method_id = data[:payment_method_id]
              charge.status = :pending
              charge.currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
              charge.save
              booking_charge = BookingDataSystem::BookingCharge.new
              booking_charge.booking = booking
              booking_charge.charge = charge
              booking_charge.save
              charge.update(:status => :done)
              booking.reload
            end
            content_type :json
            status 200
            booking.to_json
          else
            status 404
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
            result = booking.confirm!
            booking.notify_customer if booking.total_paid > 0
            result.to_json
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
            booking.notify_customer_payment_enabled
            content_type :json
            booking.to_json
          else
            status 404
          end

        end

        app.post '/api/booking/not-allow-payment/:booking_id', 
          :allowed_usergroups => ['booking_manager', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:booking_id].to_i)
            booking.force_allow_payment = false
            booking.save
            content_type :json
            booking.to_json
          else
            status 404
          end

        end        

        #
        # Assign a booking item to a booking line resource
        #
        app.post '/api/booking/assign/:id/:booking_item_reference',
          :allowed_usergroups => ['booking_manager','staff'] do

          if booking_line_resource = BookingDataSystem::BookingLineResource.get(params[:id].to_i)
            if booking_item = ::Yito::Model::Booking::BookingItem.get(params[:booking_item_reference])
              booking_line_resource.booking_item = booking_item
              booking_line_resource.save
              content_type :json
              booking_line_resource.to_json
            else
              p "Booking Line Resource not found"
              status 404
            end  
          else
            p "Booking item not found"
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
          lines_request = booking_request.delete(:booking_lines)
          extras_request = booking_request.delete(:booking_extras)
 
          booking = BookingDataSystem::Booking.get(params[:id])
          booking.transaction do |transaction|
            booking.attributes = booking_request
            booking.save
            lines_request.each do |line_booking| 
              booking_line = BookingDataSystem::BookingLine.get(line_booking[:id])
              booking_line.item_cost = line_booking[:item_cost]
              booking_line.item_unit_cost = line_booking[:item_unit_cost]
              booking_line.save
            end
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

        # Update booking resource
        #
        app.put '/api/booking-line-resource', :allowed_usergroups => ['booking_manager', 'staff'] do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys! 

          if booking_line_resource = BookingDataSystem::BookingLineResource.get(data.delete(:id).to_i)
            booking_line_resource.attributes = data
            booking_line_resource.save
            body booking_line_resource.to_json
          else
            status 404
          end

        end         

        # ------------ Send the notification emails ----------------------

        #
        # Request received
        #
        app.post '/api/booking/send-customer-req-notification/:id' , :allowed_usergroups => ['booking_manager', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:id].to_i) and 
             booking.status != :cancelled
            booking.notify_request_to_customer
            content_type :json
            booking.to_json
          else
            status 404
          end

        end

        #
        # Request received (with online payment)
        #
        app.post '/api/booking/send-customer-req-notification-pay/:id' , :allowed_usergroups => ['booking_manager', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:id].to_i) and 
             booking.status != :cancelled and 
             booking.pay_now
            booking.notify_request_to_customer_pay_now
            content_type :json
            booking.to_json
          else
            status 404
          end

        end

        #
        # Request confirmed
        #
        app.post '/api/booking/send-customer-conf-notification/:id' , :allowed_usergroups => ['booking_manager', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:id].to_i) and
             booking.status != :pending_confirmation and 
             booking.status != :cancelled
            booking.notify_customer
            content_type :json
            booking.to_json
          else
            status 404
          end

        end        

        #
        # Payment enabled
        #
        app.post '/api/booking/send-customer-pay-enabled/:id' , :allowed_usergroups => ['booking_manager', 'staff'] do

          if booking=BookingDataSystem::Booking.get(params[:id].to_i) and
             booking.status != :cancelled
            booking.notify_customer_payment_enabled
            content_type :json
            booking.to_json
          else
            status 404
          end

        end  

        # ----------------------------------------------------------------

        #
        # Booking creation (front-end)
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
          booking.init_user_agent_data(request.env["HTTP_USER_AGENT"])
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
        # Booking creation (back-end)
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
                         window.location.href= "/admin/booking/bookings"
                         </script>
                       HTML
          
          status 200
          body response

        end
      
      end

    end #BookingManagementRESTApi
  end #YSD
end #Sinatra