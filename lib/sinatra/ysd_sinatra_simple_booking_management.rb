module Sinatra
  module YSD
    #
    # Sinatra extension to manage simple bookings
    #
    module SimpleBookingManagement

      def self.registered(app)

        #
        # Bookings admin page
        #
        app.get '/admin/simple/booking/bookings/?*', :allowed_usergroups => ['booking_manager'] do 

          context = {:app => self}
          
          aspects = []
          aspects << UI::GuiBlockEntityAspectAdapter.new(GuiBlock::Audit.new, {:weight => 102, :render_in_group => true})
          aspects_render = UI::EntityManagementAspectRender.new(context, aspects) 
          
          locals = aspects_render.render(BookingDataSystem::Booking)
          locals.store(:bookings_page_size, 20)
          locals.store(:booking_item_family, 
            ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))

          load_em_page :simple_bookings_management, :booking, false, {:locals => locals}

        end

        app.get '/admin/simple/booking/hourly-occupation', :allowed_usergroups => ['booking_manager'] do 

          load_page :hourly_occupation

        end

      end

    end
  end
end