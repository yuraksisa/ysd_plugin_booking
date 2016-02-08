module Sinatra
  module YitoExtension
    module BookingActivityManagement

      def self.registered(app)
        #
        # Booking activities
        #
        app.get '/admin/booking/activities/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          locals = {:booking_activity_page_size => 20}
          load_em_page :booking_activities_management, 
                       :activity, false, :locals => locals

        end

      end

    end
  end
end
