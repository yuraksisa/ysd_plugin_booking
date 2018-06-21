module Sinatra
  module YSD
    #
    # Sinatra extension to manage bookings
    #
    module BookingReports

      def self.registered(app)


        #
        # Pending of confirmation
        #
        app.get '/admin/booking/reports/pending-confirmation', :allowed_usergroups => ['booking_manager', 'staff'] do

          locals = {}
          if product_family_id = SystemConfiguration::Variable.get_value('booking.item_family')
            product_family = ::Yito::Model::Booking::ProductFamily.get(product_family_id)
            locals.store(:product_family, product_family)
            locals.store(:booking_reservation_starts_with, product_family.frontend)
          end

          @reservations = BookingDataSystem::Booking.all(
              :conditions => {:status => [:pending_confirmation], :date_from.gte => Date.today.to_date},
              :order => :creation_date.desc)

          load_page(:report_pending_confirmation, :locals => locals)

        end

        #
        # In progress
        #
        app.get '/admin/booking/reports/in-progress', :allowed_usergroups => ['booking_manager', 'staff'] do

          @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          @today = Date.today.to_date
          @reservations = BookingDataSystem::Booking.all(
              :conditions => {:status => [:confirmed, :in_progress],
                              :date_from.lte => @today,
                              :date_to.gte => @today},
              :order => :date_to.asc)

          locals = {}
          locals.store(:booking_reservation_starts_with, @product_family.frontend)

          load_page(:report_in_progress, :locals => locals)

        end

        #
        # Pickup and return
        #
        app.get '/admin/booking/reports/pickup-return', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          locals = {}

          # Multiple locations
          multiple_locations = SystemConfiguration::Variable.get_value('booking.multiple_rental_locations', 'false').to_bool
          allow_booking_operator_multiple_locations = SystemConfiguration::Variable.get_value('booking.multiple_rental_locations_allow_operator_all_locations', 'false').to_bool
          locals.store(:multiple_rental_locations, multiple_locations)
          locals.store(:allow_booking_operator_multiple_locations, allow_booking_operator_multiple_locations)

          if multiple_locations
            locals.store(:rental_locations, ::Yito::Model::Booking::RentalLocation.all)
            rental_location_user = ::Yito::Model::Booking::RentalLocationUser.first('user.username'.to_sym => user.username)
            locals.store(:current_user_rental_location, rental_location_user.nil? ? nil : rental_location_user.rental_location)
            locals.store(:current_user_manager, user.belongs_to?('booking_manager'))
            locals.store(:current_user_operator, user.belongs_to?('booking_operator'))
          else
            locals.store(:rental_locations, [])
            locals.store(:current_user_rental_location, nil)
            locals.store(:current_user_manager, false)
            locals.store(:current_user_operator, false)
          end

          # Journal addon
          addons = mybooking_addons
          locals.store(:addons, addons)
          if addons and addons.has_key?(:addon_journal) and addons[:addon_journal]
            locals.store(:booking_journal_calendar, ::Yito::Model::Calendar::Calendar.first(name: 'booking_journal'))
          end

          # Product family
          if product_family_id = SystemConfiguration::Variable.get_value('booking.item_family')
            product_family = ::Yito::Model::Booking::ProductFamily.get(product_family_id)
            locals.store(:product_family, product_family)
          end

          load_page(:report_pickup_return, :locals => locals)
        end

        app.get '/admin/booking/reports/pickup-return-pdf', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do

          from = DateTime.now
          if params[:from]
            begin
              from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date from is not valid #{params[:from]}")
            end
          end

          to = from
          if params[:to]
            begin
              to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date to is not valid #{params[:to]}")
            end
          end

          # Rental location
          rental_location_code = nil
          multiple_locations = SystemConfiguration::Variable.get_value('booking.multiple_rental_locations', 'false').to_bool
          allow_booking_operator_multiple_locations = SystemConfiguration::Variable.get_value('booking.multiple_rental_locations_allow_operator_all_locations', 'false').to_bool
          if multiple_locations
            if params[:rental_location]
              rental_location_code = params[:rental_location]
            else
              if rental_location_user = ::Yito::Model::Booking::RentalLocationUser.first('user.username'.to_sym => user.username)
                if rental_location_user.user.belongs_to?('booking_operator')
                  rental_location_code = rental_location_user.rental_location.code unless allow_booking_operator_multiple_locations
                end
              end
            end
          end

          # Journal addon
          addons = mybooking_addons
          addon_journal = (addons and addons.has_key?(:addon_journal) and addons[:addon_journal])

          # Build report
          content_type 'application/pdf'
          if SystemConfiguration::Variable.get_value('booking.reports.pickup_return', 'v1') == 'v1'
            pdf = ::Yito::Model::Booking::Pdf::PickupReturn.new(from, to, rental_location_code,addon_journal).build.render
          else
            pdf = ::Yito::Model::Booking::Pdf::PickupReturnV2.new(from, to, rental_location_code,addon_journal).build.render
          end

        end

        #
        # Reservations report (pdf)
        #
        app.get '/admin/booking/reports/reservations-pdf/?*', :allowed_usergroups => ['booking_manager'] do

          year = Date.today.year
          date_from = Date.civil(year,1,1)
          date_to = Date.civil(year,12,31)

          if params[:from]
            begin
              date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:to]}")
            end
          end

          content_type 'application/pdf'
          pdf = ::Yito::Model::Booking::Pdf::Reservations.new(date_from, date_to).build.render
        end

        #
        # Customer Reservations report (pdf)
        #
        app.get '/admin/booking/reports/customer-reservations-pdf/?*', :allowed_usergroups => ['booking_manager'] do

          year = Date.today.year
          date_from = Date.civil(year,1,1)
          date_to = Date.civil(year,12,31)

          if params[:from]
            begin
              date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:to]}")
            end
          end

          content_type 'application/pdf'
          pdf = ::Yito::Model::Booking::Pdf::CustomerReservations.new(date_from, date_to).build.render
        end

        #
        # Reservations report (html)
        #
        app.get '/admin/booking/reports/reservations/?*', :allowed_usergroups => ['booking_manager'] do

          year = Date.today.year

          date_from = Date.civil(year,1,1)
          date_to = Date.civil(year,12,31)

          if params[:from]
            begin
              date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:to]}")
            end
          end

          condition = Conditions::JoinComparison.new('$and',
                                                     [Conditions::Comparison.new(:status, '$ne', :cancelled),
                                                      Conditions::JoinComparison.new('$or',
                                                                                     [Conditions::JoinComparison.new('$and',
                                                                                                                     [Conditions::Comparison.new(:date_from,'$lte', date_from),
                                                                                                                      Conditions::Comparison.new(:date_to,'$gte', date_from)
                                                                                                                     ]),
                                                                                      Conditions::JoinComparison.new('$and',
                                                                                                                     [Conditions::Comparison.new(:date_from,'$lte', date_to),
                                                                                                                      Conditions::Comparison.new(:date_to,'$gte', date_to)
                                                                                                                     ]),
                                                                                      Conditions::JoinComparison.new('$and',
                                                                                                                     [Conditions::Comparison.new(:date_from,'$lte', date_from),
                                                                                                                      Conditions::Comparison.new(:date_to,'$gte', date_to)
                                                                                                                     ]),
                                                                                      Conditions::JoinComparison.new('$and',
                                                                                                                     [Conditions::Comparison.new(:date_from, '$gte', date_from),
                                                                                                                      Conditions::Comparison.new(:date_to, '$lte', date_to)])
                                                                                     ]
                                                      ),
                                                     ]
          )

          @reservations = condition.build_datamapper(BookingDataSystem::Booking).all(:order => [:date_from, :time_from])
          @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {}
          locals.store(:booking_reservation_starts_with, @product_family.frontend)
          load_page(:report_reservations, :locals => locals)
        end

        #
        # Reservations report (html)
        #
        app.get '/admin/booking/reports/customer-reservations/?*', :allowed_usergroups => ['booking_manager'] do

          year = Date.today.year

          date_from = Date.civil(year,1,1)
          date_to = Date.civil(year,12,31)

          if params[:from]
            begin
              date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:to]}")
            end
          end

          condition = Conditions::JoinComparison.new('$and',
                                                     [Conditions::Comparison.new(:status, '$ne', [:cancelled, :pending_confirmation]),
                                                      Conditions::JoinComparison.new('$or',
                                                                                     [Conditions::JoinComparison.new('$and',
                                                                                                                     [Conditions::Comparison.new(:date_from,'$lte', date_from),
                                                                                                                      Conditions::Comparison.new(:date_to,'$gte', date_from)
                                                                                                                     ]),
                                                                                      Conditions::JoinComparison.new('$and',
                                                                                                                     [Conditions::Comparison.new(:date_from,'$lte', date_to),
                                                                                                                      Conditions::Comparison.new(:date_to,'$gte', date_to)
                                                                                                                     ]),
                                                                                      Conditions::JoinComparison.new('$and',
                                                                                                                     [Conditions::Comparison.new(:date_from,'$lte', date_from),
                                                                                                                      Conditions::Comparison.new(:date_to,'$gte', date_to)
                                                                                                                     ]),
                                                                                      Conditions::JoinComparison.new('$and',
                                                                                                                     [Conditions::Comparison.new(:date_from, '$gte', date_from),
                                                                                                                      Conditions::Comparison.new(:date_to, '$lte', date_to)])
                                                                                     ]
                                                      ),
                                                     ]
          )

          @reservations = condition.build_datamapper(BookingDataSystem::Booking).all(:order => [:date_from, :time_from])
          @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {}
          locals.store(:booking_reservation_starts_with, @product_family.frontend)
          load_page(:report_customer_reservations, :locals => locals)
        end


        #
        # Reservations report (html)
        #
        app.get '/admin/booking/reports/resource-reservations/?*', :allowed_usergroups => ['booking_manager'] do

          year = Date.today.year

          date_from = Date.civil(year,1,1)
          date_to = Date.civil(year,12,31)

          if params[:from]
            begin
              date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:to]}")
            end
          end

          if params[:stock_plate]
            @stock_plate = params[:stock_plate]
            if @stock_plate.empty?
              @reservations = []
            else
              @reservations = BookingDataSystem::Booking.resource_reservations(
                  date_from, date_to, @stock_plate)
            end
          else
            @stock_plate = nil
            @reservations = []
          end

          @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {}
          locals.store(:booking_reservation_starts_with, @product_family.frontend)

          load_page(:report_resource_reservations, :locals => locals)


        end

        #
        # Prereservations report (html)
        #
        app.get '/admin/booking/reports/prereservations/?*', :allowed_usergroups => ['booking_manager'] do

          year = Date.today.year

          date_from = Date.civil(year,1,1)
          date_to = Date.civil(year,12,31)

          if params[:from]
            begin
              date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("prereservation from date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("prereservation from date not valid #{params[:to]}")
            end
          end

          condition = Conditions::JoinComparison.new('$or',
                                                     [Conditions::JoinComparison.new('$and',
                                                                                     [Conditions::Comparison.new(:date_from,'$lte', date_from),
                                                                                      Conditions::Comparison.new(:date_to,'$gte', date_from)
                                                                                     ]),
                                                      Conditions::JoinComparison.new('$and',
                                                                                     [Conditions::Comparison.new(:date_from,'$lte', date_to),
                                                                                      Conditions::Comparison.new(:date_to,'$gte', date_to)
                                                                                     ]),
                                                      Conditions::JoinComparison.new('$and',
                                                                                     [Conditions::Comparison.new(:date_from,'$lte', date_from),
                                                                                      Conditions::Comparison.new(:date_to,'$gte', date_to)
                                                                                     ]),
                                                      Conditions::JoinComparison.new('$and',
                                                                                     [Conditions::Comparison.new(:date_from, '$gte', date_from),
                                                                                      Conditions::Comparison.new(:date_to, '$lte', date_to)])
                                                     ]
          )

          @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          @prereservations = condition.build_datamapper(BookingDataSystem::BookingPrereservation).all(
              :order => [:date_to, :time_to])
          locals = {}
          locals.store(:booking_reservation_starts_with, @product_family.frontend)
          load_page(:report_prereservations, :locals => locals)
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

        #
        # Charges report (pdf)
        #
        app.get '/admin/booking/reports/charges-pdf/?*', :allowed_usergroups => ['booking_manager'] do

          year = Date.today.year
          date_from = Date.civil(year,1,1)
          date_to = Date.civil(year,12,31)

          if params[:from]
            begin
              date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("charges from date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("charges from date not valid #{params[:to]}")
            end
          end

          content_type 'application/pdf'
          pdf = ::Yito::Model::Booking::Pdf::Charges.new(date_from, date_to).build.render
        end

        #
        # Charges report (html)
        #
        app.get '/admin/booking/reports/charges/?*', :allowed_usergroups => ['booking_manager'] do

          year = Date.today.year

          date_from = Date.civil(year,1,1)
          date_to = Date.civil(year,12,31)

          if params[:from]
            begin
              date_from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:from]}")
            end
          end

          if params[:to]
            begin
              date_to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("reservation from date not valid #{params[:to]}")
            end
          end

          @charges = BookingDataSystem::Booking.charges(date_from, date_to)
          load_page(:report_charges)

        end

        #
        # Stock report (pdf)
        #
        app.get '/admin/booking/reports/stock-pdf', :allowed_usergroups => ['booking_manager'] do

          content_type 'application/pdf'
          pdf = ::Yito::Model::Booking::Pdf::Stock.new().build.render

        end

        #
        # Stock report
        #
        app.get '/admin/booking/reports/stock/?*', :allowed_usergroups => ['booking_manager'] do

          @stocks = ::Yito::Model::Booking::BookingItem.all(
              :conditions => {:active => true},
              :order => [:category_code, :reference, :stock_model, :stock_plate])

          load_page(:report_stock)

        end

      end
    end
  end
end