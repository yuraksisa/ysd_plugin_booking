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
        app.get '/console/booking', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:console_booking)
        end

        #
        # Booking configuration
        #
        app.get '/config/booking', :allowed_usergroups => ['booking_manager', 'staff'] do
          locals = {:families => Hash[ *::Yito::Model::Booking::ProductFamily.all.collect { |v| [v.code, v.code]}.flatten ]  }
          load_page(:config_booking, {:locals => locals})
        end

        #
        # Bookings planning
        # 
        app.get '/admin/bookings/planning', :allowed_usergroups => ['booking_manager', 'staff'] do
          load_page(:bookings_planning)
        end

        #
        # Booking rates management
        #
        app.get '/admin/bookings/rates', :allowed_usergroups => ['booking_manager', 'staff'] do
          
          context = {:app => self}
          locals = {}
          
          seasonBlock = ::Yito::View::Block::SeasonBlock.new
          ratesBlock = ::Yito::View::Block::RatesBlock.new

          locals.store(:season_block, seasonBlock.html(context))
          locals.store(:rates_block, ratesBlock.html(context))
          locals.store(:scripts, seasonBlock.jscript(context) << ratesBlock.jscript(context))

          load_page(:booking_rates, :locals => locals)
        end

        #
        # Bookings scheduler
        #
        app.get '/admin/bookings/scheduler', :allowed_usergroups => ['booking_manager', 'staff'] do

          load_page(:bookings_scheduler)

        end

        #
        # Create new booking (administation)
        #
        app.get '/admin/bookings/new', :allowed_usergroups => ['booking_manager', 'staff'] do

          locals = {}

          locals.store(:admin_mode, true)
          locals.store(:confirm_booking_url, '/booking-from-manager')

          locals.store(:booking_item_family, 
            ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))

          locals.store(:booking_item_type,
            SystemConfiguration::Variable.get_value('booking.item_type'))
       
          locals.store(:booking_payment,
            SystemConfiguration::Variable.get_value('booking.payment', 'false').to_bool)

          locals.store(:booking_deposit,
            SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i)

          locals.store(:booking_min_days,
            SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i)

          locals.store(:booking_allow_custom_pickup_return_place,
            SystemConfiguration::Variable.get_value('booking.allow_custom_pickup_return_place', 'false').to_bool)

          if booking_js=ContentManagerSystem::Template.find_by_name('booking_js') and 
             not booking_js.text.empty?
            locals.store(:booking_js, booking_js.text) 
          end
                 
          load_page('reserva-online'.to_sym, :locals => locals)


        end

        #
        # Bookings admin page
        #
        app.get '/admin/bookings/?*', :allowed_usergroups => ['booking_manager'] do 

          context = {:app => self}
          
          aspects = []
          aspects << UI::GuiBlockEntityAspectAdapter.new(GuiBlock::Audit.new, {:weight => 102, :render_in_group => true})
          aspects_render = UI::EntityManagementAspectRender.new(context, aspects) 
          
          locals = aspects_render.render(BookingDataSystem::Booking)
          locals.store(:bookings_page_size, 20)

          load_em_page :bookings_management, :booking, false, {:locals => locals}

        end

      end

  	end #BookingManagement
  end #YSD
end #Sinatra