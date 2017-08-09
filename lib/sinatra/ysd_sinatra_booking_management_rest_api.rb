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

      #
      # Get the booking occupation for the dates
      #
      # @params[Hash]
      #
      #   from : Date from
      #   to   : Date to
      #
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

      #
      # Get the booking extras occupation for the dates
      #
      # @params [Hash]
      #
      #   from: Date from
      #   to: Date to
      #
      def booking_extras_occupation(params)

        if params['from'].nil? or params['to'].nil?
           []
        else
           begin
             from = DateTime.strptime(params[:from], '%Y-%m-%d')
             to = DateTime.strptime(params[:to], '%Y-%m-%d')
             BookingDataSystem::Booking.extras_occupation(from, to).map do |item|  
                {extra_id: item.extra_id, stock: item.stock, busy: item.busy}
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
          to = (from >> 1) - 1

          condition = Conditions::JoinComparison.new('$and',
           [Conditions::Comparison.new(:status, '$in', [:confirmed,:in_progress,:done]),
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
                 [Conditions::Comparison.new(:date_from,'$lte', from),
                  Conditions::Comparison.new(:date_to,'$gte', to)
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
          to = (from >> 1) - 1

          condition = Conditions::JoinComparison.new('$and',
           [Conditions::Comparison.new(:status, '$in', [:confirmed,:in_progress,:done]),
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
                 [Conditions::Comparison.new(:date_from,'$lte', from),
                  Conditions::Comparison.new(:date_to,'$gte', to)
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

          extras_occupation_hash = booking_extras_occupation(params).inject({}) do |result, item|
                                     result.store(item[:extra_id], {stock: item[:stock], busy: item[:busy]})
                                     result
                                   end

          result = {:availability => availability,
                    :payment => booking_payment_enabled(params),
                    :stock => stock_hash,
                    :extras_stock => extras_occupation_hash}
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
        # Check resources available for a period
        #
        app.get '/api/booking/available-resources', :allowed_usergroups => ['booking_manager', 'staff']  do 

          if params[:from]
            begin
              @date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("date not valid #{params[:from]}")
            end

            if params[:to]
              begin
                @date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
              rescue
                logger.error("date not valid #{params[:to]}")
              end
              data, detail = BookingDataSystem::Booking.resources_occupation(@date_from, @date_to)
              status 200
              detail.to_json
            else
              status 500
            end 
          else
            status 500
          end

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

          bookings.to_json(:only => [:id, :date_from, :time_from, :date_to, :time_to, :customer_name, 
                           :customer_surname, :planning_color],
                           :relationships => {:booking_line_resources => {}})

        end
        
        #
        # Planning summary
        #
        app.get '/api/booking/planning-summary', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          today = Date.today
          @date_from = Date.civil(today.year, today.month, 1)
          @date_to = Date.civil(today.year, today.month, -1)          

          if params[:from]
            begin
              @date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              @date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("date not valid #{params[:to]}")
            end
          end  
          
          @options = nil
          if params[:reference]
            @options = {mode: :stock, reference: params[:reference]}
          elsif params[:product]
            @options = {mode: :product, product: params[:product]}
          end

          p "from: #{params[:from]} #{@date_from} to: #{params[:to]} #{@date_to}"

          result = BookingDataSystem::Booking.planning(@date_from, @date_to, @options)

          content_type :json
          result.to_json
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

          bookings.to_json(:only => [:id, :date_from, :time_from, :date_to, :time_to, :customer_name, :customer_surname,
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
            :order => [:date_from.asc, :time_from.asc]).sort do |x,y| 
              comp = x.date_from <=> y.date_from 
              comp.zero? ? Time.parse(x.time_from) <=> Time.parse(y.time_from) : comp
             end

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
            :order => [:date_to.asc, :time_to.asc]).sort do |x,y| 
               comp = x.date_to <=> y.date_to 
               comp.zero? ? Time.parse(x.time_to) <=> Time.parse(y.time_to) : comp
             end 

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

            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))
              if search_request.has_key?('search')
                total, data = BookingDataSystem::Booking.text_search(search_request['search'],offset_order_query)
              else
                data, total = BookingDataSystem::Booking.all_and_count(offset_order_query)
              end
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
              booking_line_resource.booking_item_category = booking_item.category.code if booking_item.category
              booking_line_resource.booking_item_reference = booking_item.reference
              booking_line_resource.booking_item_stock_model = booking_item.stock_model
              booking_line_resource.booking_item_stock_plate = booking_item.stock_plate
              booking_line_resource.booking_item_characteristic_1 = booking_item.characteristic_1
              booking_line_resource.booking_item_characteristic_2 = booking_item.characteristic_2
              booking_line_resource.booking_item_characteristic_3 = booking_item.characteristic_3
              booking_line_resource.booking_item_characteristic_4 = booking_item.characteristic_4              
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
        
        #
        # Update booking supplements
        #
        app.post '/api/booking/booking-supplements', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!
          
          id = data_request[:booking_id]
          time_from_cost = data_request[:time_from_cost]
          time_to_cost = data_request[:time_to_cost]
          pickup_place_cost = data_request[:pickup_place_cost]
          return_place_cost = data_request[:return_place_cost]                              

          if booking = BookingDataSystem::Booking.get(id)
            if data_request[:time_from_cost] or data_request[:time_to_cost] or
               data_request[:pickup_place_cost] or data_request[:return_place_cost] 
              booking_deposit = SystemConfiguration::Variable.get_value('booking.deposit', 0).to_i
              old_total_supplements = booking.time_from_cost + booking.time_to_cost +
                                      booking.pickup_place_cost + booking.return_place_cost
              booking.time_from_cost = time_from_cost 
              booking.time_to_cost = time_to_cost 
              booking.pickup_place_cost = pickup_place_cost 
              booking.return_place_cost = return_place_cost
              total_supplements = booking.time_from_cost + booking.time_to_cost +
                                  booking.pickup_place_cost + booking.return_place_cost
              booking.total_cost += (total_supplements - old_total_supplements)
              booking.total_pending += (total_supplements - old_total_supplements)
              booking.booking_amount += ((total_supplements - old_total_supplements) * booking_deposit / 100).round unless booking_deposit == 0 
              booking.save
              booking.reload
              content_type :json
              booking.to_json
            else
              body "Ningún suplemento especificado"
            end
          else
            status 404
          end

        end

        #
        # Create booking line
        #
        app.post '/api/booking/booking-line', :allowed_usergroups => ['booking_manager', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_id]

          if booking = BookingDataSystem::Booking.get(id)
            if data_request[:item_id] and data_request[:quantity]
              item_id = data_request[:item_id]
              quantity = data_request[:quantity].to_i
              product_lines = booking.booking_lines.select do |booking_line|
                                booking_line.item_id == item_id
                              end
              if product_lines.empty?
                if product = ::Yito::Model::Booking::BookingCategory.get(item_id)
                  booking_deposit = SystemConfiguration::Variable.get_value('booking.deposit', 0).to_i
                  product_unit_cost = product.unit_price(booking.date_from, booking.days)
                  product_deposit_cost = product.deposit
                  booking.transaction do 
                    # Create booking line
                    booking_line = BookingDataSystem::BookingLine.new
                    booking_line.booking = booking
                    booking_line.item_id = item_id 
                    booking_line.item_description = product.name 
                    booking_line.item_unit_cost_base = product_unit_cost
                    booking_line.item_unit_cost = product_unit_cost
                    booking_line.item_cost = product_unit_cost * quantity
                    booking_line.quantity = quantity
                    booking_line.product_deposit_unit_cost = product_deposit_cost
                    booking_line.product_deposit_cost = product_deposit_cost * quantity
                    booking_line.save
                    # Create booking line resources
                    (1..quantity).each do |resource_number|
                      booking_line_resource = BookingDataSystem::BookingLineResource.new 
                      booking_line_resource.booking_line = booking_line
                      booking_line_resource.save
                    end
                    # Update booking cost
                    item_cost_increment = product_unit_cost * quantity
                    deposit_cost_increment = product_deposit_cost * quantity
                    total_cost_increment = item_cost_increment + deposit_cost_increment
                    booking.item_cost += item_cost_increment
                    booking.product_deposit_cost += deposit_cost_increment
                    booking.total_cost += total_cost_increment
                    booking.total_pending += total_cost_increment
                    booking.booking_amount += (total_cost_increment * booking_deposit / 100).round unless booking_deposit == 0
                    booking.save
                  end
                  booking.reload
                  content_type :json
                  booking.to_json
                else
                  body "Producto no existe"
                  status 500 
                end
              else
                body "Ya existe el producto en la reserva. Por favor, modifique la cantidad"
                status 500
              end
            else 
              body "Producto o cantidad no especificadas"
              status 500
            end
          else
            status 404
          end
        end
        
        #
        # Create booking extra
        #
        app.post '/api/booking/booking-extra', :allowed_usergroups => ['booking_manager', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_id]

          if booking = BookingDataSystem::Booking.get(id)
            if data_request[:extra_id] and data_request[:quantity]
              extra_id = data_request[:extra_id]
              quantity = data_request[:quantity].to_i
              booking_extras = booking.booking_extras.select do |booking_extra|
                                 booking_extra.extra_id == extra_id
                               end
              if booking_extras.empty?
                if extra = ::Yito::Model::Booking::BookingExtra.get(extra_id)
                  booking_deposit = SystemConfiguration::Variable.get_value('booking.deposit', 0).to_i
                  extra_unit_cost = extra.unit_price(booking.date_from, booking.days)
                  booking.transaction do 
                    # Create the booking extra line
                    booking_extra = BookingDataSystem::BookingExtra.new
                    booking_extra.booking = booking
                    booking_extra.extra_id = extra_id
                    booking_extra.extra_description = extra.name
                    booking_extra.quantity = quantity
                    booking_extra.extra_unit_cost = extra_unit_cost
                    booking_extra.extra_cost = extra_unit_cost * quantity
                    booking_extra.save
                    # Updates the booking
                    extra_cost_increment = extra_unit_cost * quantity
                    total_cost_increment = extra_cost_increment
                    booking.extras_cost += extra_cost_increment
                    booking.total_cost += total_cost_increment
                    booking.total_pending += total_cost_increment
                    booking.booking_amount += (total_cost_increment * booking_deposit / 100).round unless booking_deposit == 0
                    booking.save
                  end
                  booking.reload
                  content_type :json
                  booking.to_json
                else
                  body "Extra no existe"
                  status 500 
                end
              else
                body "Ya existe el extra en la reserva. Por favor, modifique la cantidad"
                status 500
              end
            else 
              body "Extra o cantidad no especificadas"
              status 500
            end
          else
            status 404
          end
        end

        #
        # Update booking line item
        #
        app.put '/api/booking/booking-line/item-id', :allowed_usergroups => ['booking_manager', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!          
          id = data_request[:booking_line_id]
          if booking_line = BookingDataSystem::BookingLine.get(id)
            if data_request[:item_id] && data_request[:item_id] != booking_line.item_id
              item_id = data_request[:item_id]
              if product = ::Yito::Model::Booking::BookingCategory.get(item_id)
                booking = booking_line.booking 
                booking_deposit = SystemConfiguration::Variable.get_value('booking.deposit', 0).to_i
                item_description = product.name
                old_price = new_price = booking_line.item_unit_cost
                old_product_deposit = new_product_deposit = booking_line.product_deposit_unit_cost
                if data_request[:price_modification] and data_request[:price_modification] == 'update'                 
                  new_price = product.unit_price(booking.date_from, booking.days).round
                  new_product_deposit = product.deposit
                end
                # Update the booking line and the booking
                booking_line.transaction do
                  item_cost_increment = new_price - old_price
                  deposit_cost_increment = new_product_deposit - old_product_deposit
                  total_cost_increment = item_cost_increment + deposit_cost_increment              
                  # Update booking line
                  booking_line.item_id = item_id
                  booking_line.item_description = item_description
                  if item_cost_increment != 0
                    booking_line.item_unit_cost += item_cost_increment
                    booking_line.item_cost = booking_line.item_unit_cost * booking_line.quantity
                  end
                  if deposit_cost_increment != 0
                    booking_line.product_deposit_unit_cost += deposit_cost_increment
                    booking_line.product_deposit_cost = booking_line.product_deposit_unit_cost * booking_line.quantity
                  end
                  booking_line.save
                  # Update booking
                  if item_cost_increment > 0 || deposit_cost_increment > 0
                    booking.item_cost += item_cost_increment
                    booking.product_deposit_cost += deposit_cost_increment
                    booking.total_cost += total_cost_increment
                    booking.total_pending += total_cost_increment
                    booking.booking_amount += (total_cost_increment * booking_deposit / 100).round unless booking_deposit == 0
                    booking.save
                  end
                  booking.reload
                  content_type :json
                  booking.to_json                                    
                end
              else
                body "Producto no existe"
                status 500
              end
            else
              body "Producto no especificado"
              status 500
            end
          else
            status 404
          end
            
        end

        #
        # Update booking line: quantity
        #
        app.put '/api/booking/booking-line/quantity', :allowed_usergroups => ['booking_manager', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!
          id = data_request[:booking_line_id]
          if booking_line = BookingDataSystem::BookingLine.get(id)
            if data_request[:quantity]
              quantity = data_request[:quantity]
              if product = ::Yito::Model::Booking::BookingCategory.get(booking_line.item_id)
                booking_deposit = SystemConfiguration::Variable.get_value('booking.deposit', 0).to_i
                booking = booking_line.booking
                #product_unit_cost = product.unit_price(booking.date_from, booking.days)
                product_deposit_cost = product.deposit
                old_quantity = booking_line.quantity
                old_booking_line_item_cost = booking_line.item_cost
                old_booking_line_product_deposit_cost = booking_line.product_deposit_cost
                booking_line.transaction do 
                  booking_line.quantity = quantity
                  #booking_line.item_unit_cost = product_unit_cost
                  booking_line.item_cost = booking_line.item_unit_cost * quantity
                  booking_line.product_deposit_unit_cost = product_deposit_cost
                  booking_line.product_deposit_cost = product_deposit_cost * quantity                  
                  booking_line.save
                  # Add or remove booking line resources
                  if quantity < old_quantity
                    (quantity..(old_quantity-1)).each do |resource_number|
                      booking_line.booking_line_resources[quantity].destroy unless booking_line.booking_line_resources[quantity].nil?
                    end  
                  elsif quantity > old_quantity
                    (old_quantity..(quantity-1)).each do |resource_number|
                      booking_line_resource = BookingDataSystem::BookingLineResource.new 
                      booking_line_resource.booking_line = booking_line
                      booking_line_resource.save
                    end
                  end
                  # Update the booking (cost)
                  item_cost_increment = booking_line.item_cost - old_booking_line_item_cost
                  deposit_cost_increment = booking_line.product_deposit_cost - old_booking_line_product_deposit_cost
                  total_cost_increment = item_cost_increment + deposit_cost_increment
                  booking.item_cost += item_cost_increment
                  booking.product_deposit_cost += deposit_cost_increment
                  booking.total_cost += total_cost_increment
                  booking.total_pending += total_cost_increment
                  booking.booking_amount += (total_cost_increment * booking_deposit / 100).round unless booking_deposit == 0
                  booking.save
                end
                booking.reload
                content_type :json
                booking.to_json
              else
                body "Producto no existe. Imposible recalcular precio"
                status 500
              end  
            else 
              body "Cantidad no especificada"
              status 500
            end
          else
            status 404
          end

        end
        
        #
        # Update booking line : item cost
        #
        app.put '/api/booking/booking-line/item-cost', :allowed_usergroups => ['booking_manager', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_line_id]
          if booking_line = BookingDataSystem::BookingLine.get(id)
            if data_request[:item_unit_cost]
              item_unit_cost = data_request[:item_unit_cost]
              if product = ::Yito::Model::Booking::BookingCategory.get(booking_line.item_id)
                booking_deposit = SystemConfiguration::Variable.get_value('booking.deposit', 0).to_i
                booking = booking_line.booking
                old_booking_line_item_cost = booking_line.item_cost
                booking_line.transaction do 
                  booking_line.item_unit_cost = item_unit_cost
                  booking_line.item_cost = booking_line.item_unit_cost * booking_line.quantity
                  booking_line.save
                  # Update the booking (cost)
                  item_cost_increment = booking_line.item_cost - old_booking_line_item_cost
                  total_cost_increment = item_cost_increment
                  booking.item_cost += item_cost_increment
                  booking.total_cost += total_cost_increment
                  booking.total_pending += total_cost_increment
                  booking.booking_amount += (total_cost_increment * booking_deposit / 100).round unless booking_deposit == 0
                  booking.save
                end
                booking.reload
                content_type :json
                booking.to_json
              else
                body "Producto no existe. Imposible recalcular precio"
                status 500
              end  
            else 
              body "Coste no especificado"
              status 500
            end
          else
            status 404
          end

        end

        #
        # Update booking line: deposit
        #
        app.put '/api/booking/booking-line/deposit', :allowed_usergroups => ['booking_manager', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_line_id]
          if booking_line = BookingDataSystem::BookingLine.get(id)
            if data_request[:item_deposit]
              booking_deposit = SystemConfiguration::Variable.get_value('booking.deposit', 0).to_i
              item_deposit = data_request[:item_deposit]
              booking = booking_line.booking
              old_booking_line_product_deposit_cost = booking_line.product_deposit_cost
              booking_line.transaction do 
                booking_line.product_deposit_unit_cost = (item_deposit / booking_line.quantity).round
                booking_line.product_deposit_cost = item_deposit
                booking_line.save
                # Update the booking (cost)
                deposit_cost_increment = booking_line.product_deposit_cost - old_booking_line_product_deposit_cost
                total_cost_increment = deposit_cost_increment
                booking.total_cost += total_cost_increment
                booking.total_pending += total_cost_increment
                booking.booking_amount += (total_cost_increment * booking_deposit / 100).round unless booking_deposit == 0
                booking.save
              end
              booking.reload
              content_type :json
              booking.to_json
            else 
              body "Fianza no especificada"
              status 500
            end
          else
            status 404
          end

        end
        

        #
        # Update booking line item
        #
        app.put '/api/booking/booking-line/item', :allowed_usergroups => ['booking_manager', 'staff'] do

        end

        #
        # Update booking extra: quantity
        #
        app.put '/api/booking/booking-extra/quantity', :allowed_usergroups => ['booking_manager', 'staff'] do


          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_extra_id]
          if booking_extra = BookingDataSystem::BookingExtra.get(id)
            if data_request[:quantity]
              quantity = data_request[:quantity]
              if extra = ::Yito::Model::Booking::BookingExtra.get(booking_extra.extra_id)
                booking_deposit = SystemConfiguration::Variable.get_value('booking.deposit', 0).to_i
                booking = booking_extra.booking
                #extra_unit_cost = extra.unit_price(booking.date_from, booking.days)
                old_quantity = booking_extra.quantity
                old_booking_extra_extra_cost = booking_extra.extra_cost
                booking_extra.transaction do 
                  booking_extra.quantity = quantity
                  #booking_extra.extra_unit_cost = extra_unit_cost
                  booking_extra.extra_cost = booking_extra.extra_unit_cost * quantity
                  booking_extra.save
                  # Update the booking (cost)
                  extra_cost_increment = booking_extra.extra_cost - old_booking_extra_extra_cost
                  total_cost_increment = extra_cost_increment 
                  booking.extras_cost += extra_cost_increment
                  booking.total_cost += total_cost_increment
                  booking.total_pending += total_cost_increment
                  booking.booking_amount += (total_cost_increment * booking_deposit / 100).round unless booking_deposit == 0
                  booking.save
                end
                booking.reload
                content_type :json
                booking.to_json
              else
                body "Extra no existe. Imposible recalcular precio"
                status 500
              end  
            else 
              body "Cantidad no especificada"
              status 500
            end
          else
            status 404
          end

        end
        
        #
        # Update booking extra : extra cost
        #
        app.put '/api/booking/booking-extra/extra-cost', :allowed_usergroups => ['booking_manager', 'staff'] do

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          id = data_request[:booking_extra_id]
          if booking_extra = BookingDataSystem::BookingExtra.get(id)
            if data_request[:extra_unit_cost]
              extra_unit_cost = data_request[:extra_unit_cost]
              if extra = ::Yito::Model::Booking::BookingExtra.get(booking_extra.extra_id)
                booking_deposit = SystemConfiguration::Variable.get_value('booking.deposit', 0).to_i
                booking = booking_extra.booking
                old_booking_extra_extra_cost = booking_extra.extra_cost
                booking_extra.transaction do 
                  booking_extra.extra_unit_cost = extra_unit_cost
                  booking_extra.extra_cost = booking_extra.extra_unit_cost * booking_extra.quantity
                  booking_extra.save
                  # Update the booking (cost)
                  extra_cost_increment = booking_extra.extra_cost - old_booking_extra_extra_cost
                  total_cost_increment = extra_cost_increment
                  booking.extras_cost += extra_cost_increment
                  booking.total_cost += total_cost_increment
                  booking.total_pending += total_cost_increment
                  booking.booking_amount += (total_cost_increment * booking_deposit / 100).round unless booking_deposit == 0
                  booking.save
                end
                booking.reload
                content_type :json
                booking.to_json
              else
                body "Extra no existe. Imposible recalcular precio"
                status 500
              end  
            else 
              body "Coste no especificado"
              status 500
            end
          else
            status 404
          end

        end

        #
        # Update booking resource
        #
        app.put '/api/booking-line-resource', :allowed_usergroups => ['booking_manager', 'staff'] do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys! 

          if booking_line_resource = BookingDataSystem::BookingLineResource.get(data.delete(:id).to_i)
            booking_item_reference = data.delete(:booking_item_reference)
            if booking_item_reference != booking_line_resource.booking_item_reference
              if booking_item = ::Yito::Model::Booking::BookingItem.get(booking_item_reference) 
                booking_line_resource.booking_item_category = booking_item.category.code if booking_item.category
                booking_line_resource.booking_item_reference = booking_item.reference
                booking_line_resource.booking_item_stock_model = booking_item.stock_model
                booking_line_resource.booking_item_stock_plate = booking_item.stock_plate
                booking_line_resource.booking_item_characteristic_1 = booking_item.characteristic_1
                booking_line_resource.booking_item_characteristic_2 = booking_item.characteristic_2
                booking_line_resource.booking_item_characteristic_3 = booking_item.characteristic_3
                booking_line_resource.booking_item_characteristic_4 = booking_item.characteristic_4              
              end
            end
            booking_line_resource.attributes = data
            booking_line_resource.save
            body booking_line_resource.to_json
          else
            status 404
          end

        end   

        #
        # Delete booking line
        #
        app.delete '/api/booking/booking-line', :allowed_usergroups => ['booking_manager', 'staff'] do
        
        end

        #
        # Delete a booking extra
        #
        app.delete '/api/booking/booking-extra', :allowed_usergroups => ['booking_manager', 'staff'] do

          if booking_extra = BookingDataSystem::BookingExtra.get(params[:id])
            booking = booking_extra.booking
            booking_extra.transaction do 
              booking.extras_cost -= booking_extra.extra_cost
              booking.total_cost -= booking_extra.extra_cost
              if booking.total_pending < booking_extra.extra_cost
                booking.total_pending = 0
              else
                booking.total_pending -= booking_extra.extra_cost
              end
              booking_deposit = SystemConfiguration::Variable.get_value('booking.deposit', 0).to_i
              booking.booking_amount -= (booking_extra.extra_cost * booking_deposit / 100).round unless booking_deposit == 0
              booking.save
              booking_extra.destroy 
            end
            booking.reload
            content_type :json
            booking.to_json
          else
            logger.error("Booking extra #{params[:id]} not found")
            status 404
          end

        end

        #
        # Delete a booking charge
        #
        app.delete '/api/booking/booking-charge/?*', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          if booking_charge = BookingDataSystem::BookingCharge.first(:booking_id => params[:booking_id],
                                                                     :charge_id => params[:charge_id])
            booking = booking_charge.booking
            charge = booking_charge.charge
            booking_charge.transaction do
              if charge.status == :done 
                booking.total_paid -= charge.amount
                booking.total_pending += charge.amount
                booking.save
              end
              charge.destroy
              booking_charge.destroy
            end
            booking.reload
            content_type :json
            booking.to_json
          else
            logger.error("Booking charge #{params[:charge_id]} for #{params[:booking_id]} not found")
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