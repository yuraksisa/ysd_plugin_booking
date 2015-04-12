require 'ui/ysd_ui_entity_management_aspect_render' unless defined?UI::EntityManagementAspectRender
require 'ui/ysd_ui_guiblock_entity_aspect_adapter'
require 'ysd_plugin_cms' unless defined?GuiBlock::Audit
require 'ysd_md_booking' unless defined?BookingDataSystem::Booking

module Sinatra
  module YSD
  	#
  	# Sinatra extension to manage bookings
  	#
  	module BookingManagement

      def self.registered(app)
        
        #
        # Booking console
        #
        app.get '/admin/booking/console', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          locals = {}
          if product_family_id = SystemConfiguration::Variable.get_value('booking.item_family')
            product_family = ::Yito::Model::Booking::ProductFamily.get(product_family_id)
            locals.store(:product_family, product_family)
          end
          load_page(:console_booking, :locals => locals)
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
        # Bookings summary
        #
        app.get '/admin/booking/summary', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:bookings_statistics)
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
        ['/admin/booking/new/:booking_catalog_code', '/admin/booking/new'].each do |path|
          app.get path, :allowed_usergroups => ['booking_manager', 'staff'] do

            catalog = request_catalog

            locals = {}

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

            booking_js = catalog_template(catalog)

            if booking_js and not booking_js.text.empty?
              locals.store(:booking_js, booking_js.text) 
            end
                 
            load_page('reserva-online'.to_sym, :locals => locals)
          
          end
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
          locals.store(:bookings_page_size, 12)
          locals.store(:booking_item_family, 
            ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))

          load_em_page :bookings_management, :booking, false, {:locals => locals}

        end

      end

  	end #BookingManagement
  end #YSD
end #Sinatra