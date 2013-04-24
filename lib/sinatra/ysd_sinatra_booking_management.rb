module Sinatra
  module YSD
  	#
  	# Sinatra extension to manage bookings
  	#
  	module BookingManagement

      def self.registered(app)

        app.get '/admin/bookings' do 
          load_page :bookings_management, :locals => {:bookings_page_size => 20}
        end

      end

  	end #ChargeManagement
  end #YSD
end #Sinatra