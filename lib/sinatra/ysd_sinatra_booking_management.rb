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
        
        #
        # Booking dashboard
        #
        app.get '/admin/booking/dashboard', :allowed_usergroups => ['booking_manager', 'staff'] do
          today = Date.today
          @year = DateTime.now.year
          @received_reservations = BookingDataSystem::Booking.count_received_reservations(@year)
          @pending_confirmation_reservations = BookingDataSystem::Booking.count_pending_confirmation_reservations(@year)
          @confirmed_reservations = BookingDataSystem::Booking.count_confirmed_reservations(@year)
          @reservations_by_weekday = BookingDataSystem::Booking.reservations_by_weekday(@year)
          @reservations_by_category = BookingDataSystem::Booking.reservations_by_category(@year)
          @reservations_by_status = BookingDataSystem::Booking.reservations_by_status(@year)
          @last_30_days_reservations = BookingDataSystem::Booking.last_30_days_reservations
          @pickup_today = BookingDataSystem::Booking.count_pickup(today)
          @transit_today = BookingDataSystem::Booking.count_transit(today)
          @delivery_today = BookingDataSystem::Booking.count_delivery(today)
          load_page(:booking_dashboard)
        end

        #
        # Booking configuration
        #
        app.get "/admin/booking/config", :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:console_booking_configuration)
        end

        #
        # Booking create rates
        #
        app.get "/admin/booking/create-rates", :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:booking_create_rates)
        end

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
                    :reservation_starts_with => {
                       :dates => t.booking_settings.form.reservation_starts_with.dates, 
                       :categories => t.booking_settings.form.reservation_starts_with.categories,
                       :shopcart => t.booking_settings.form.reservation_starts_with.shoppingcart} }
          load_page(:config_booking, {:locals => locals})
        end

        app.get '/admin/booking/config/templates', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          contract = ContentManagerSystem::Template.first({:name => 'booking_contract'})
          conditions = ContentManagerSystem::Content.first({:alias => '/renting_conditions'})
          summary_message = ContentManagerSystem::Template.first({:name => 'booking_summary_message'})      
          b_m_n = ContentManagerSystem::Template.first({:name => 'booking_manager_notification'})
          b_m_n_pay_now = ContentManagerSystem::Template.first({:name => 'booking_manager_notification_pay_now'})
          b_m_r_c = ContentManagerSystem::Template.first({:name => 'booking_customer_req_notification'})
          b_m_r_c_pay_now = ContentManagerSystem::Template.first({:name => 'booking_customer_req_pay_now_notification'})
          b_m_c_c = ContentManagerSystem::Template.first({:name => 'booking_customer_notification'})
          b_m_c_c_pay_enabled = ContentManagerSystem::Template.first({:name => 'booking_customer_notification_payment_enabled'})

          locals = {:conditions => conditions,
                    :contract => contract,
                    :summary_message => summary_message,
                    :b_m_n => b_m_n, 
                    :b_m_n_pay_now => b_m_n_pay_now, 
                    :b_m_r_c => b_m_r_c,
                    :b_m_r_c_pay_now => b_m_r_c_pay_now, 
                    :b_m_c_c => b_m_c_c,
                    :b_m_c_c_pay_enabled => b_m_c_c_pay_enabled}

          load_page(:console_booking_configuration_templates, :locals => locals)
        end

        #
        # Booking availability
        #
        app.get '/admin/booking/availability', :allowed_usergroups => ['booking_manager', 'staff'] do
          redirect '/admin/calendar/calendars' 
        end

        #
        # Bookings planning
        # 
        app.get '/admin/booking/planning', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:bookings_planning)
        end

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

        #
        # Bookings summary
        #
        app.get '/admin/booking/summary', :allowed_usergroups => ['booking_manager', 'staff'] do
          first = BookingDataSystem::Booking.first(order: :creation_date.asc, limit: 1)
          first_year = first ? first.creation_date.year : Date.today.year
          current_year = Date.today.year
          load_page(:bookings_statistics, :locals => {first_year: first_year, current_year: current_year})
        end

        #
        # Booking rates management
        #
        app.get '/admin/booking/rates', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          locals = {}
          locals.store(:booking_categories, ::Yito::Model::Booking::BookingCategory.all)
          load_page(:console_booking_rates, :locals => locals)

        end

        #
        # Create new booking (administation)
        #
        app.route :get, :post, ['/admin/booking/new/:booking_catalog_code', '/admin/booking/new'], :allowed_usergroups => ['booking_manager', 'staff'] do

            catalog = request_catalog

            locals = {}

            booking = if params[:customer_name] and params[:customer_surname] and
                         params[:customer_phone] and params[:customer_email]
                        BookingDataSystem::Booking.first_customer_booking(params)
                      else
                        nil
                      end 
          
            locals.store(:admin_mode, true)
            locals.store(:confirm_booking_url, '/api/booking-from-manager')
            locals.store(:booking_reservation_starts_with,
              catalog ? catalog.selector.to_sym : SystemConfiguration::Variable.get_value('booking.reservation_starts_with', :dates).to_sym)
            locals.store(:booking_item_family, 
              catalog ? catalog.product_family : ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))
            locals.store(:booking_item_type,
              SystemConfiguration::Variable.get_value('booking.item_type'))
            locals.store(:booking_payment,
              SystemConfiguration::Variable.get_value('booking.payment', 'false').to_bool)
            locals.store(:booking_deposit,
              SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i)
            locals.store(:booking_min_days,
              SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i)
            locals.store(:booking_payment_cadence,
              SystemConfiguration::Variable.get_value('booking.payment_cadence', '0').to_i)          
            locals.store(:booking_allow_custom_pickup_return_place,
              SystemConfiguration::Variable.get_value('booking.allow_custom_pickup_return_place', 'false').to_bool)
            locals.store(:booking, booking)
            locals.store(:promotion_codes_active, ::Yito::Model::Rates::PromotionCode.active?(Date.today))
            locals.store(:offer_discount, ::Yito::Model::Rates::Discount.active(Date.today).first)

            booking_js = catalog_template(catalog)

            if booking_js and not booking_js.text.empty?
              locals.store(:booking_js, booking_js.text) 
            end
                 
            load_page('reserva-online'.to_sym, :locals => locals)
          
        end

        #
        # Edit the pick-up/return date
        #
        app.get '/admin/booking/edit/pickup-return/:booking_id', :allowed_usergroups => ['booking_manager'] do

          if booking = BookingDataSystem::Booking.get(params[:booking_id])
            if booking_category = ::Yito::Model::Booking::BookingCategory.get(booking.booking_lines.first.item_id)

              catalog = booking_category.booking_catalog
              locals = {}
              locals.store(:booking_item_family, 
                catalog ? catalog.product_family : ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))
              locals.store(:booking_allow_custom_pickup_return_place,
                SystemConfiguration::Variable.get_value('booking.allow_custom_pickup_return_place', 'false').to_bool)
              locals.store(:booking_deposit,
                SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i) 
              locals.store(:booking, booking)

              booking_js = catalog_template(catalog)

              if booking_js and not booking_js.text.empty?
                locals.store(:booking_js, booking_js.text) 
              end

              load_page(:booking_edit_pickupreturn, :locals => locals)
            else
              status 404
            end
          else
            status 404
          end

        end

        #
        # Bookings admin page
        #
        app.get '/admin/booking/bookings/?*', :allowed_usergroups => ['booking_manager'] do 

          context = {:app => self}
          
          aspects = []
          aspects << UI::GuiBlockEntityAspectAdapter.new(GuiBlock::Audit.new, {:weight => 102, :render_in_group => true})
          aspects_render = UI::EntityManagementAspectRender.new(context, aspects) 
          
          locals = aspects_render.render(BookingDataSystem::Booking)
          locals.store(:bookings_page_size, 20)
          locals.store(:booking_item_family, 
            ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))
          locals.store(:booking_payment_enabled, SystemConfiguration::Variable.get_value('booking.payment', false))

          load_em_page :bookings_management, :booking, false, {:locals => locals}

        end
        
        # ------------------ Occupation ---------------------

        #
        # Get the product occupation for a month
        #
        app.get '/admin/booking/monthly-occupation', :allowed_usergroups => ['booking_manager','staff'] do

          today = Date.today
          
          @month = params[:month].to_i == 0 ? today.month : params[:month].to_i
          @year = params[:year].to_i == 0 ? today.year : params[:year].to_i
          @product = params[:product]

          @period = Date.civil(@year, @month)
          @next_period = @period >> 1
          @previous_period = @period << 1

          @days = Date.civil(@year, @month, -1).day
          @data = BookingDataSystem::Booking.monthly_occupation(@month, @year, @product)
          
          load_page :monthly_occupation

        end

        # ------------------- Contract --------------------

        #
        # Contract
        #
        app.get '/admin/booking/contract/:id', :allowed_usergroups => ['booking_manager','staff'] do

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

        # ------------------- Reports ---------------------

        #
        # Pickup and return
        #
        app.get '/admin/booking/reports/pickup-return', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          locals = {}
          if product_family_id = SystemConfiguration::Variable.get_value('booking.item_family')
            product_family = ::Yito::Model::Booking::ProductFamily.get(product_family_id)
            locals.store(:product_family, product_family)
          end
          load_page(:pickup_return, :locals => locals)
        end

        app.get '/admin/booking/reports/pickup-return-pdf', :allowed_usergroups => ['booking_manager', 'staff'] do

           from = DateTime.now
           if params[:from]
             begin
               from = DateTime.strptime(params[:from], '%Y-%m-%d')
             rescue
             end
           end

           to = from
           if params[:to]
             begin
               to = DateTime.strptime(params[:to], '%Y-%m-%d')
             rescue
             end
           end

           content_type 'application/pdf'
           pdf = ::Yito::Model::Booking::Pdf::PickupReturn.new(from, to).build.render

        end

        #
        # Reservations report (html)
        #
        app.get '/admin/booking/reports/reservations', :allowed_usergroups => ['booking_manager'] do 
          year = Date.today.year
          date_from = Date.civil(year,1,1)
          date_to = Date.civil(year,12,31)
          @reservations = BookingDataSystem::Booking.all(
             :conditions => {:date_from.gte => date_from,
                             :date_to.lte => date_to,
                             :status.not => :cancelled},
             :order => [:date_from, :time_from])
          locals = {}
          locals.store(:booking_reservation_starts_with,
              SystemConfiguration::Variable.get_value('booking.reservation_starts_with', :dates).to_sym)          
          load_page(:report_reservations, :locals => locals)
        end  
        
        #
        # Reservations report (pdf)
        #
        app.get '/admin/booking/reports/reservations-pdf', :allowed_usergroups => ['booking_manager'] do 
          year = Date.today.year

          content_type 'application/pdf'
          pdf = ::Yito::Model::Booking::Pdf::Reservations.new(year).build.render          
        end  

        #
        # Customers report (html)
        #
        app.get '/admin/booking/reports/customers', :allowed_usergroups => ['booking_manager'] do

          @item_count, @reservations = BookingDataSystem::Booking.customer_search(params[:search],{})
          load_page(:report_customers)

        end     

        #
        # Customers report (pdf)
        #
        app.get '/admin/booking/reports/customers-pdf', :allowed_usergroups => ['booking_manager'] do

          content_type 'application/pdf'
          pdf = ::Yito::Model::Booking::Pdf::Customers.new().build.render   

        end 

      end

  	end #BookingManagement
  end #YSD
end #Sinatra