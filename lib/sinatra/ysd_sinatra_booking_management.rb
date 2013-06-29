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