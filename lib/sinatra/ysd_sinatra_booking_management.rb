require 'ui/ysd_ui_entity_management_aspect_render' unless defined?UI::EntityManagementAspectRender
require 'ui/ysd_ui_guiblock_entity_aspect_adapter'
require 'ysd_plugin_cms' unless defined?GuiBlock::Audit
require 'ysd_md_booking' unless defined?BookingDataSystem::Booking
require 'prawn' unless defined?Prawn
require 'prawn/format' unless defined?Prawn
require 'prawn/table' unless defined?Prawn::Table

module Sinatra
  module YSD
  	#
  	# Sinatra extension to manage bookings
  	#
  	module BookingManagement

      def self.registered(app)

        # ----------------------------- DASHBOARD -------------------------------------------------

        #
        # Booking dashboard
        #
        app.get '/admin/booking/dashboard', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          @booking_renting = true
          @booking_activities = false
          if settings.respond_to?(:mybooking_plan)  
            @booking_renting = [:pro_renting,:pro_plus].include?(settings.mybooking_plan)
            @booking_activities = [:pro_activities, :pro_plus].include?(settings.mybooking_plan)
          end

          @today = Date.today
          @year = DateTime.now.year
          @total_billing = 0
          @first_day_today_month = Date.civil(@today.year, @today.month, 1)
          @first_day_next_year = Date.civil(@today.year + 1, @today.month, 1)  
    
          if @booking_renting 
            @pickup_today = BookingDataSystem::Booking.count_pickup(@today)
            @transit_today = BookingDataSystem::Booking.count_transit(@today)
            @delivery_today = BookingDataSystem::Booking.count_delivery(@today)
            @received_reservations = BookingDataSystem::Booking.count_received_reservations(@year)
            @pending_confirmation_reservations = BookingDataSystem::Booking.count_pending_confirmation_reservations(@year)
            @confirmed_reservations = BookingDataSystem::Booking.count_confirmed_reservations(@year)
            @reservations_by_category = BookingDataSystem::Booking.reservations_by_category(@year)
            @reservations_by_status = BookingDataSystem::Booking.reservations_by_status(@year)
            @reservations_by_weekday = BookingDataSystem::Booking.reservations_by_weekday(@year)
            @last_30_days_reservations = BookingDataSystem::Booking.last_30_days_reservations
            @product_total_billing = BookingDataSystem::Booking.products_billing_total(@year) || 0
            @extras_total_billing = BookingDataSystem::Booking.extras_billing_total(@year) || 0
            @total_billing += @product_total_billing
            @total_billing += @extras_total_billing
            @total_charged_reservations = BookingDataSystem::Booking.total_charged(@year)
            @total_should_charged_reservations = BookingDataSystem::Booking.total_should_charged(
                                      Date.civil(@year, 1, 1),
                                      @today)
            @forecast_charged_reservations = BookingDataSystem::Booking.forecast_charged(@first_day_today_month, @first_day_next_year)
          end

          if @booking_activities
            @today_start_activities = ::Yito::Model::Order::Order.count_start(@today)
            @received_orders = ::Yito::Model::Order::Order.count_received_orders(@year)
            @pending_confirmation_orders = ::Yito::Model::Order::Order.count_pending_confirmation_orders(@year)
            @confirmed_orders = ::Yito::Model::Order::Order.count_confirmed_orders(@year)
            @activities_by_category = ::Yito::Model::Order::Order.activities_by_category(@year)
            @activities_by_status = ::Yito::Model::Order::Order.activities_by_status(@year)
            @activities_by_weekday = ::Yito::Model::Order::Order.activities_by_weekday(@year)
            @last_30_days_activities = ::Yito::Model::Order::Order.last_30_days_activities
            @activities_total_billing = ::Yito::Model::Order::Order.activities_billing_total(@year) || 0
            @total_billing += @activities_total_billing
            @total_charged_activities = ::Yito::Model::Order::Order.total_charged(@year)
            @total_should_charged_activities = ::Yito::Model::Order::Order.total_should_charged(
                                      Date.civil(@year, 1, 1),
                                      @today)
            @forecast_charged_activities = ::Yito::Model::Order::Order.forecast_charged(@first_day_today_month, @first_day_next_year)

          end

          @product_total_cost = BookingDataSystem::Booking.stock_cost_total || 0

          load_page(:booking_dashboard)
        end

        # ------------------------ Create Rates (TO REMOVE) -------------------------------------------

        #
        # Booking create rates
        #
        app.get "/admin/booking/create-rates", :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:booking_create_rates)
        end

        # --------------------- Configuration ----------------------------------------------------------

        #
        # Booking configuration
        #
        app.get "/admin/booking/config", :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:console_booking_configuration)
        end


        # -------------------- Configuration : GENERAL -------------------------------------------------

        #
        # Booking configuration (general)
        #
        app.get '/admin/booking/config/general', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          pickup_return_timetables = {"" => t.booking_settings.form.no_pickup_return_timetable}.merge(Hash[ *::Yito::Model::Calendar::Timetable.all.collect { |tt| [tt.id.to_s, tt.name] }.flatten])

          locals = {:families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.code]}.flatten ],
                    :pickup_return_timetables => pickup_return_timetables,
                    :booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :booking_modes => {
                      :rent => t.booking_settings.form.booking_mode.rent,
                      :restaurant => t.booking_settings.form.booking_mode.restaurant
                    },
                    :calendar_modes => {
                      :first_day =>  t.booking_settings.form.calendar_mode.first_day,
                      :default => t.booking_settings.form.calendar_mode.default
                    },
                    :reservation_starts_with => {
                       :dates => t.booking_settings.form.reservation_starts_with.dates, 
                       :categories => t.booking_settings.form.reservation_starts_with.categories,
                       :shopcart => t.booking_settings.form.reservation_starts_with.shoppingcart} }
          locals.store(:booking_renting, 
              SystemConfiguration::Variable.get_value('booking.renting','false').to_bool)        
          locals.store(:booking_activities, 
              SystemConfiguration::Variable.get_value('booking.activities','false').to_bool)        
         
          load_page(:config_booking, {:locals => locals})
        end

        # --------------------- Configuration : Templates --------------------------------------------

        app.get '/admin/booking/config/templates', :allowed_usergroups => ['booking_manager', 'staff'] do

          booking_renting = SystemConfiguration::Variable.get_value('booking.renting','false').to_bool
          booking_activities = SystemConfiguration::Variable.get_value('booking.activities','false').to_bool
          
          if booking_renting
            contract = ContentManagerSystem::Template.first({:name => 'booking_contract'})
            conditions = ContentManagerSystem::Content.first({:alias => '/renting_conditions'})
            summary_message = ContentManagerSystem::Template.first({:name => 'booking_summary_message'})      
            b_m_n = ContentManagerSystem::Template.first({:name => 'booking_manager_notification'})
            b_m_n_pay_now = ContentManagerSystem::Template.first({:name => 'booking_manager_notification_pay_now'})
            b_m_c_n = ContentManagerSystem::Template.first({:name => 'booking_confirmation_manager_notification'})
            b_m_r_c = ContentManagerSystem::Template.first({:name => 'booking_customer_req_notification'})
            b_m_r_c_pay_now = ContentManagerSystem::Template.first({:name => 'booking_customer_req_pay_now_notification'})
            b_m_c_c = ContentManagerSystem::Template.first({:name => 'booking_customer_notification'})
            b_m_c_c_pay_enabled = ContentManagerSystem::Template.first({:name => 'booking_customer_notification_payment_enabled'})
          end

          if booking_activities 
            o_m_n = ContentManagerSystem::Template.first({:name => 'order_manager_notification'})
            o_m_n_pay_now = ContentManagerSystem::Template.first({:name => 'order_manager_notification_pay_now'})
            o_m_c_n = ContentManagerSystem::Template.first({:name => 'order_confirmation_manager_notification'})
            o_m_r_c = ContentManagerSystem::Template.first({:name => 'order_customer_req_notification'})
            o_m_r_c_pay_now = ContentManagerSystem::Template.first({:name => 'order_customer_req_pay_now_notification'})
            o_m_c_c = ContentManagerSystem::Template.first({:name => 'order_customer_notification'})
            o_m_c_c_pay_enabled = ContentManagerSystem::Template.first({:name => 'order_customer_notification_payment_enabled'})
          end

          locals = {:booking_renting => booking_renting,
                    :booking_activities => booking_activities}

          locals.merge!({:conditions => conditions,
                    :contract => contract,
                    :summary_message => summary_message,
                    :b_m_n => b_m_n, 
                    :b_m_n_pay_now => b_m_n_pay_now, 
                    :b_m_c_n => b_m_c_n,
                    :b_m_r_c => b_m_r_c,
                    :b_m_r_c_pay_now => b_m_r_c_pay_now, 
                    :b_m_c_c => b_m_c_c,
                    :b_m_c_c_pay_enabled => b_m_c_c_pay_enabled})  if booking_renting   

          locals.merge!({:o_m_n => o_m_n, 
                    :o_m_n_pay_now => o_m_n_pay_now, 
                    :o_m_c_n => o_m_c_n,
                    :o_m_r_c => o_m_r_c,
                    :o_m_r_c_pay_now => o_m_r_c_pay_now, 
                    :o_m_c_c => o_m_c_c,
                    :o_m_c_c_pay_enabled => o_m_c_c_pay_enabled})  if booking_activities   

          load_page(:console_booking_configuration_templates, :locals => locals)
        end

        #
        # Booking availability
        #
        app.get '/admin/booking/availability', :allowed_usergroups => ['booking_manager', 'staff'] do
          redirect '/admin/calendar/calendars' 
        end

        # ---------------------------- SCHEDULER ----------------------------------------------------

        #
        # Bookings scheduler
        #
        app.get '/admin/booking/scheduler/:booking_item_reference', :allowed_usergroups => ['booking_manager', 'staff'] do
          today = DateTime.now
          year = params[:year] || today.year
          month = params[:month] || (today.month - 1)
          booking_item = ::Yito::Model::Booking::BookingItem.get(params[:booking_item_reference])
          if booking_item
            load_page(:bookings_scheduler, :locals => {:booking_item => booking_item, :year => year, :month => month})
          else
            status 404
          end

        end

        #
        # Bookings scheduler
        #
        app.get '/admin/booking/scheduler/?*', :allowed_usergroups => ['booking_manager', 'staff'] do
          today = DateTime.now
          year = params[:year] || today.year
          month = params[:month] || (today.month - 1)
          load_page(:bookings_scheduler, :locals => {:booking_item => nil, :year => year, :month => month})
        end

        # --------------------------------- SUMARY -----------------------------------------------------

        #
        # Bookings summary
        #
        app.get '/admin/booking/summary', :allowed_usergroups => ['booking_manager', 'staff'] do
          first = BookingDataSystem::Booking.first(order: :creation_date.asc, limit: 1)
          first_year = first ? first.creation_date.year : Date.today.year
          current_year = Date.today.year
          load_page(:bookings_statistics, :locals => {first_year: first_year, current_year: current_year})
        end

        # ----------------------------- RATES ---------------------------------------------------------

        #
        # Booking rates management
        #
        app.get '/admin/booking/rates', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          locals = {}
          locals.store(:booking_categories, ::Yito::Model::Booking::BookingCategory.all)
          load_page(:console_booking_rates, :locals => locals)

        end

        # --------------------------------- EDIT BOOKING ------------------------------------------------------

        #
        # Change reservation period or pickup/return places
        #
        app.get '/admin/booking/edit/pickup-return/:booking_id', :allowed_usergroups => ['booking_manager', 'booking_operator'] do

          if booking = BookingDataSystem::Booking.get(params[:booking_id])
            if booking_category = ::Yito::Model::Booking::BookingCategory.get(booking.booking_lines.first.item_id)

              catalog = booking_category.booking_catalog
              locals = {}

              locals.store(:booking, booking)

              locals.store(:booking_item_family,
                           catalog ? catalog.product_family : ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))

              locals.store(:booking_allow_custom_pickup_return_place,
                SystemConfiguration::Variable.get_value('booking.allow_custom_pickup_return_place', 'false').to_bool)
              locals.store(:booking_custom_pickup_return_place_cost, BigDecimal.new(SystemConfiguration::Variable.get_value('booking.custom_pickup_return_place_price', '0')))

              pickup_return_place_def = nil
              pickup_return_place_def_id = SystemConfiguration::Variable.get_value('booking.pickup_return_place_definition','0').to_i
              if pickup_return_place_def_id > 0
                pickup_return_place_def = ::Yito::Model::Booking::PickupReturnPlaceDefinition.get(pickup_return_place_def_id)
              end
              pickup_return_place_def = ::Yito::Model::Booking::PickupReturnPlaceDefinition.first if pickup_return_place_def.nil?
              locals.store(:booking_pickup_return_places, pickup_return_place_def.pickup_return_places)

              locals.store(:booking_deposit,
                SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i) 

              load_page(:booking_edit_pickupreturn, :locals => locals)

            else
              status 404
            end
          else
            status 404
          end

        end

        # -------------------------- ADMIN BOOKINGS ------------------------------------

        #
        # Bookings admin page
        #
        app.get '/admin/booking/bookings/?*', :allowed_usergroups => ['booking_manager', 'booking_operator'] do

          context = {:app => self}
          
          aspects = []
          aspects << UI::GuiBlockEntityAspectAdapter.new(GuiBlock::Audit.new, {:weight => 102, :render_in_group => true})
          aspects_render = UI::EntityManagementAspectRender.new(context, aspects) 
          
          locals = aspects_render.render(BookingDataSystem::Booking)
          locals.store(:bookings_page_size, 20)
          locals.store(:booking_item_family, 
            ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))
          locals.store(:booking_payment_enabled, SystemConfiguration::Variable.get_value('booking.payment', false))
          locals.store(:booking_front_end_prefix, SystemConfiguration::Variable.get_value('booking.front_end_prefix', ''))

          addon_simple_invoicing = (settings.respond_to?(:mybooking_addon_simple_invoicing) ? settings.mybooking_addon_simple_invoicing : false)
          locals.store(:booking_addon_simple_invoicing, addon_simple_invoicing)
          
          load_em_page :bookings_management, :booking, false, {:locals => locals}

        end



        # ------------------- Contract --------------------

        #
        # Contract
        #
        app.get '/admin/booking/contract/:id', :allowed_usergroups => ['booking_manager', 'booking_operator','staff'] do

           if booking = BookingDataSystem::Booking.get(params[:id])
             product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
             if contract_template = ContentManagerSystem::Template.first({:name => 'booking_contract'})
               content_type 'application/pdf'
               eval contract_template.text
             else
               status 404
             end 
           else
             status 404
           end

        end         

        # ------------------- Assign stock ----------------

        #
        # Assign stock
        #
        app.get '/admin/booking/assign-stock/:id', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          if @booking_line_resource = BookingDataSystem::BookingLineResource.get(params[:id])
            @booking = @booking_line_resource.booking_line.booking
            @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
            product_category = if @booking_line_resource.booking_item_category.nil? or 
                                  @booking_line_resource.booking_item_category.empty?
                                 @booking_line_resource.booking_line.item_id
                               else
                                 @booking_line_resource.booking_item_category
                               end
            @data,@detail = BookingDataSystem::Booking.resources_occupation(
              @booking.date_from, @booking.date_to,
              product_category)

            @assigned = !@booking_line_resource.booking_item_reference.nil?
            load_page :booking_line_resource_assign_stock
          else
            status 404
          end
        end


      end

  	end #BookingManagement
  end #YSD
end #Sinatra