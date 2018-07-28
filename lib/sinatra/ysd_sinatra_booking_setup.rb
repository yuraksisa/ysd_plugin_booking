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
        # Setup step 1
        #
        app.get "/admin/booking/setup-step-1", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan_type.first
            @current_type_of_business = SystemConfiguration::Variable.get_value('booking.item_family', nil)
            @types_of_business = ::Yito::Model::Booking::ProductFamily.all(order: [:presentation_order])
            load_page(:setup_step_1)
          else
            status 404
          end

        end

        #
        # Setup step 1 (POST)
        #
        app.post "/admin/booking/setup-step-1", :allowed_usergroups => ['booking_manager', 'staff'] do

          if params[:type_of_business]
            if params[:type_of_business] != SystemConfiguration::Variable.get_value('booking.item_family', nil)
              SystemConfiguration::Variable.set_value('booking.item_family', params[:type_of_business])
            end
          end

          redirect '/admin/booking/setup-step-2'

        end

        #
        # Setup step 2
        #
        app.get "/admin/booking/setup-step-2", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan_type.first
            @calendar_modes =  {
                :first_day =>  t.booking_settings.form.calendar_mode.first_day,
                :default => t.booking_settings.form.calendar_mode.default
            }
            load_page(:setup_step_2)
          else
            status 404
          end

        end

        #
        # Setup step 2 (POST)
        #
        app.post "/admin/booking/setup-step-2", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan_type.first

            if min_days = params['booking.min_days'.to_sym]
              SystemConfiguration::Variable.set_value('booking.min_days', min_days)
            end

            redirect '/admin/booking/setup-step-3'

          else
            status 404
          end

        end

        #
        # Setup step 3
        #
        app.get "/admin/booking/setup-step-3", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan_type.first
            load_page(:setup_step_3)
          else
            status 404
          end

        end

        #
        # Setup step 3 (POST)
        #
        app.post "/admin/booking/setup-step-3", :allowed_usergroups => ['booking_manager', 'staff'] do

          redirect '/admin/booking/setup-step-4'

        end

        #
        # Setup step 4
        #
        app.get "/admin/booking/setup-step-4", :allowed_usergroups => ['booking_manager', 'staff'] do

          if mybooking_plan_type.first
            load_page(:setup_step_4)
          else
            status 404
          end

        end

        #
        # Setup step 4 (POST)
        #
        app.post "/admin/booking/setup-step-4", :allowed_usergroups => ['booking_manager', 'staff'] do

          redirect '/admin/booking/setup'

        end


        #
        # Booking configuration
        #
        #app.get "/admin/booking/config", :allowed_usergroups => ['booking_manager', 'staff'] do
        #  load_page(:console_booking_configuration)
        #end

      end
    end
  end
end