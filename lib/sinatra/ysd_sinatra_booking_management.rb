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

          @booking_renting, @booking_activities = mybooking_plan_type

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

          #locals.store(:elements_actions, partial(:bookings_management_header))

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
          addons = mybooking_addons
          @addon_sales_channels = (addons and addons.has_key?(:addon_sales_channels) and addons[:addon_sales_channels])
          @multilanguage = settings.multilanguage_site
          @languages = Model::Translation::TranslationLanguage.all
          @default_language = settings.default_language
          @step2_confirmation = SystemConfiguration::Variable.get_value('booking.frontend.confirmation_step_2', 'false').to_bool

          if @addon_sales_channels
            @sales_channels = ::Yito::Model::SalesChannel::SalesChannel.all
            @booking_frontend_prefix_sales_channels = {}
            @sales_channels.each do |sales_channel|
              @booking_frontend_prefix_sales_channels.store(sales_channel.code,
                                                            SystemConfiguration::Variable.get_value("booking.front_end_prefix_sc_#{sales_channel.code}",
                                                                                                    locals[:booking_front_end_prefix]))
            end
          end

          load_em_page :bookings_management, :booking, false, {:locals => locals}

        end

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

              locals.store(:pickup_return_places_configuration,
                           SystemConfiguration::Variable.get_value('booking.pickup_return_places_configuration', 'list'))
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


        # ------------------- Contract --------------------

        #
        # Print the contract (PDF document)
        #
        app.get '/admin/booking/contract/:id', :allowed_usergroups => ['booking_manager', 'booking_operator','staff'] do

           if booking = BookingDataSystem::Booking.get(params[:id])
             product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
             if contract_template = ContentManagerSystem::Template.first({:name => 'booking_contract'})
               contract_template = contract_template.translate(booking.customer_language)
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
        # Assign stock assistant
        # -------------------------------------------------------------
        #
        # It's a wizard to allow the stock assignation to a reservation
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