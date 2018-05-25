module Sinatra
  module YSD
    #
    # Sinatra extension to setup booking plugin - First time use -
    #
    module BookingSetup

      def self.registered(app)

        #
        # Setup the platform
        #
        app.get "/admin/booking/setup", :allowed_usergroups => ['booking_manager', 'staff'] do

          @booking_renting, @booking_activities = mybooking_plan_type

          load_page(:setup)

        end

        # ------------------------------ Renting setup ------------------------------------------------

        #
        # Renting setup step 1
        #
        app.get "/admin/booking/setup-renting-1", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan_type.first
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

          if mybooking_plan_type.first
            load_page(:setup_renting_step_2)
          else
            status 404
          end

        end

        #
        # Renting setup step 2 (POST)
        #
        app.post "/admin/booking/setup-renting-2", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan_type.first

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

          if mybooking_plan_type.first
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

          if mybooking_plan_type.first
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

      end
    end
  end
end