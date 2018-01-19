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

          @booking_renting, @booking_activities = mybooking_plan

          @today = Date.today
          @year = DateTime.now.year
          @total_billing = 0
          @first_day_today_month = Date.civil(@today.year, @today.month, 1)
          @first_day_next_year = Date.civil(@today.year + 1, @today.month, 1)

          @total_charged = {total: 0, detail: {}}
          @forecast_charged = {total: 0, detail: {}}

          if @booking_renting 
            @pickup_today = BookingDataSystem::Booking.count_pickup(@today)
            @transit_today = BookingDataSystem::Booking.count_transit(@today)
            @delivery_today = BookingDataSystem::Booking.count_delivery(@today)
            @received_reservations = BookingDataSystem::Booking.count_received_reservations(@year)
            @pending_confirmation_reservations = BookingDataSystem::Booking.count_pending_confirmation_reservations(@year)
            @confirmed_reservations = BookingDataSystem::Booking.count_confirmed_reservations(@year)
            @reservations_by_category = BookingDataSystem::Booking.reservations_by_category(@year).first(5)
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
            #
            @total_charged = @total_charged_reservations.clone
            @forecast_charged = @forecast_charged_reservations.clone
          end

          if @booking_activities
            @today_start_activities = ::Yito::Model::Order::Order.count_start(@today)
            @received_orders = ::Yito::Model::Order::Order.count_received_orders(@year)
            @pending_confirmation_orders = ::Yito::Model::Order::Order.count_pending_confirmation_orders(@year)
            @confirmed_orders = ::Yito::Model::Order::Order.count_confirmed_orders(@year)
            @activities_by_category = ::Yito::Model::Order::Order.activities_by_category(@year).first(5)
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

            if @total_charged.has_key?(:total)
              @total_charged[:total] += @total_charged_activities[:total] if @total_charged_activities.has_key?(:total)
            else
              @total_charged[:total] = @total_charged_activities[:total]
            end
            @total_charged_activities[:detail].each do |k,v|
              if @total_charged[:detail].has_key?(k)
                @total_charged[:detail][k][:value] += v[:value]
              else
                @total_charged[:detail][k] = v
              end
            end

            if @forecast_charged.has_key?(:total)
              @forecast_charged[:total] += @forecast_charged_activities[:total] if @forecast_charged_activities.has_key?(:total)
            else
              @forecast_charged[:total] = @forecast_charged_activities[:total]
            end

            if @forecast_charged.has_key?(:detail)
              @forecast_charged_activities[:detail].each do |k,v|
                if @forecast_charged[:detail].has_key?(k)
                  @forecast_charged[:detail][k] += v
                else
                  @forecast_charged[:detail][k] = v
                end
              end
            else
              @forecast_charged[:detail] = @forecast_charged_activities[:detail]
            end
          end

          @product_total_cost = BookingDataSystem::Booking.stock_cost_total || 0

          load_page(:booking_dashboard)
        end

        # ----------------------------------------------------------------------------------------------
        # ----------------------------------- Setup ----------------------------------------------------
        # ----------------------------------------------------------------------------------------------

        #
        # Setup the platform
        #
        app.get "/admin/booking/setup", :allowed_usergroups => ['booking_manager', 'staff'] do

          @booking_renting, @booking_activities = mybooking_plan

          load_page(:setup)

        end

        # ------------------------------ Renting setup ------------------------------------------------

        #
        # Renting setup step 1
        #
        app.get "/admin/booking/setup-renting-1", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan.first
            @current_type_of_business = SystemConfiguration::Variable.get_value('booking.item_family', nil)
            @types_of_business = ::Yito::Model::Booking::ProductFamily.all(order: [:presentation_order])
            load_page(:setup_renting_step_1)
          else
            status 404
          end

        end

        #
        # Renting setup step 1 (POST)
        #
        app.post "/admin/booking/setup-renting-1", :allowed_usergroups => ['booking_manager', 'staff'] do

          if params[:type_of_business]
            if params[:type_of_business] != SystemConfiguration::Variable.get_value('booking.item_family', nil)
              SystemConfiguration::Variable.set_value('booking.item_family', params[:type_of_business])
            end
          end

          redirect '/admin/booking/setup-renting-2'

        end

        #
        # Renting setup step 2
        #
        app.get "/admin/booking/setup-renting-2", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan.first
            load_page(:setup_renting_step_2)
          else
            status 404
          end

        end

        #
        # Renting setup step 2 (POST)
        #
        app.post "/admin/booking/setup-renting-2", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan.first

            if min_days = params['booking.min_days'.to_sym]
              SystemConfiguration::Variable.set_value('booking.min_days', min_days)
            end

            redirect '/admin/booking/setup-renting-3'

          else
            status 404
          end

        end

        #
        # Renting setup step 3
        #
        app.get "/admin/booking/setup-renting-3", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan.first
            load_page(:setup_renting_step_3)
          else
            status 404
          end

        end

        #
        # Renting setup step 3 (POST)
        #
        app.post "/admin/booking/setup-renting-3", :allowed_usergroups => ['booking_manager', 'staff'] do

          redirect '/admin/booking/setup-renting-4'

        end

        #
        # Renting setup step 4
        #
        app.get "/admin/booking/setup-renting-4", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan.first
            load_page(:setup_renting_step_4)
          else
            status 404
          end

        end

        #
        # Renting setup step 4 (POST)
        #
        app.post "/admin/booking/setup-renting-4", :allowed_usergroups => ['booking_manager', 'staff'] do

          redirect '/admin/booking/setup'

        end


        # ----------------------------- Activities setup ----------------------------------------------

        #
        #
        #
        app.get "/admin/booking/setup-activities-1", :allowed_usergroups => ['booking_manager', 'staff'] do

        end

        # --------------------- Configuration ----------------------------------------------------------

        #
        # Booking configuration
        #
        app.get "/admin/booking/config", :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:console_booking_configuration)
        end


        # -------------------- Configuration  ---------------------------------------------------------

        #
        # Booking configuration (reservations)
        #
        app.get '/admin/booking/config/business', :allowed_usergroups => ['booking_manager', 'staff'] do

          booking_renting, booking_activities = mybooking_plan
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],
                    :calendar_modes => {
                        :first_day =>  t.booking_settings.form.calendar_mode.first_day,
                        :default => t.booking_settings.form.calendar_mode.default
                    }}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          load_page(:config_booking_business, {:locals => locals})

        end

        #
        # Booking configuration (reservations)
        #
        app.get '/admin/booking/config/reservations', :allowed_usergroups => ['booking_manager', 'staff'] do

          pickup_return_timetables = {"" => t.booking_settings.form.no_pickup_return_timetable}.merge(Hash[ *::Yito::Model::Calendar::Timetable.all.collect { |tt| [tt.id.to_s, tt.name] }.flatten])
          booking_renting, booking_activities = mybooking_plan
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          use_factors = SystemConfiguration::Variable.get_value('booking.use_factors_in_rates','false').to_bool
          locals = {:booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],
                    :calendar_modes => {
                        :first_day =>  t.booking_settings.form.calendar_mode.first_day,
                        :default => t.booking_settings.form.calendar_mode.default
                    },
                    :use_factors => use_factors,
                    :pickup_return_timetables => pickup_return_timetables}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          if booking_item_family and booking_item_family.driver
            locals.store(:booking_driver_age_rule_definition, SystemConfiguration::Variable.get_value('booking.driver_min_age.rule_definition'))
            locals.store(:booking_driver_age_rule_definitions, Hash[ *::Yito::Model::Booking::BookingDriverAgeRuleDefinition.all.collect { |v| [v.id.to_s, v.name]}.flatten])
          end
          load_page(:config_booking_reservations, {:locals => locals})

        end

        #
        # Booking configuration (reservations)
        #
        app.get '/admin/booking/config/backoffice', :allowed_usergroups => ['booking_manager', 'staff'] do

          booking_renting, booking_activities = mybooking_plan
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          multiple_locations = SystemConfiguration::Variable.get_value('booking.multiple_rental_locations', 'false').to_bool
          locals = {:booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],
                    :multiple_locations => multiple_locations}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)

          load_page(:config_booking_backoffice, {:locals => locals})

        end

        #
        # Booking configuration (payment)
        #
        app.get '/admin/booking/config/payment', :allowed_usergroups => ['booking_manager', 'staff'] do
          booking_renting, booking_activities = mybooking_plan
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          load_page(:config_booking_payment, {:locals => locals})
        end

        #
        # Booking configuration (notifications)
        #
        app.get '/admin/booking/config/notifications', :allowed_usergroups => ['booking_manager', 'staff'] do
          booking_renting, booking_activities = mybooking_plan
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:booking_mode => SystemConfiguration::Variable.get_value('booking.mode','rent'),
                    :families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.name]}.flatten ],}
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_renting, booking_renting)
          locals.store(:booking_activities, booking_activities)
          load_page(:config_booking_notifications, {:locals => locals})
        end

        #
        # Booking configuration (notifications) - renting customer messages templates
        #
        app.get '/admin/booking/config/notifications/renting-customer-templates', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:config_booking_renting_notifications_customer_templates)
        end

        #
        # Booking configuration (notifications) - renting manager messages templates
        #
        app.get '/admin/booking/config/notifications/renting-manager-templates', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:config_booking_renting_notifications_manager_templates)
        end

        #
        # Booking configuration (notifications) - activities customer messages templates
        #
        app.get '/admin/booking/config/notifications/activities-customer-templates', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:config_booking_activities_notifications_customer_templates)
        end

        #
        # Booking configuration (notifications) - activities manager messages templates
        #
        app.get '/admin/booking/config/notifications/activities-manager-templates', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:config_booking_activities_notifications_manager_templates)
        end

        #
        # Booking configuration contract
        #
        app.get '/admin/booking/config/contract', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:config_booking_contract)
        end

        #
        # Booking configuration frontend
        #
        app.get '/admin/booking/config/front-end', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:config_booking_frontend)
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
          locals.store(:multiple_rental_locations, SystemConfiguration::Variable.get_value('booking.multiple_rental_locations', 'false').to_bool)
          locals.store(:driver_min_age_rules, SystemConfiguration::Variable.get_value('booking.driver_min_age.rules', 'false').to_bool)
          locals.store(:elements_actions, partial(:bookings_management_header))

          # Simple invoicing addon
          addons = mybooking_addons
          addon_simple_invoicing = (addons and addons.has_key?(:addon_simple_invoicing) and addons[:addon_simple_invoicing])
          locals.store(:booking_addon_simple_invoicing, addon_simple_invoicing)

          @today = Date.today
          @year = DateTime.now.year
          @transit_today = BookingDataSystem::Booking.count_transit(@today)
          @pending_confirmation_reservations = BookingDataSystem::Booking.count_pending_confirmation_reservations(@year)
          @received_reservations = BookingDataSystem::Booking.count_received_reservations(@year)
          @confirmed_reservations = BookingDataSystem::Booking.count_confirmed_reservations(@year)
          load_em_page :bookings_management, :booking, false, {:locals => locals}

        end



        #
        # Check the extras occupation
        # 
        app.get '/admin/booking/extras-occupation', :allowed_usergroups => ['booking_manager','staff'] do 

          @date_from = Date.today
          @date_to = Date.today + 7

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

          @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          @data,@detail = BookingDataSystem::Booking.extras_resources_occupation(@date_from, @date_to)
          
          load_page :extras_occupation

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