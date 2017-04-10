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
          locals.store(:booking_reservation_starts_with,
                       SystemConfiguration::Variable.get_value('booking.reservation_starts_with', :dates).to_sym)
          if product_family_id = SystemConfiguration::Variable.get_value('booking.item_family')
            product_family = ::Yito::Model::Booking::ProductFamily.get(product_family_id)
            locals.store(:product_family, product_family)
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

          locals = {}
          locals.store(:booking_reservation_starts_with,
                       SystemConfiguration::Variable.get_value('booking.reservation_starts_with', :dates).to_sym)
          @product_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))

          @today = Date.today.to_date

          @reservations = BookingDataSystem::Booking.all(
              :conditions => {:status => [:confirmed, :in_progress],
                              :date_from.lte => @today,
                              :date_to.gte => @today},
              :order => :date_to.asc)

          load_page(:report_in_progress, :locals => locals)

        end

        #
        # Pickup and return
        #
        app.get '/admin/booking/reports/pickup-return', :allowed_usergroups => ['booking_manager', 'staff'] do

          locals = {}
          if product_family_id = SystemConfiguration::Variable.get_value('booking.item_family')
            product_family = ::Yito::Model::Booking::ProductFamily.get(product_family_id)
            locals.store(:product_family, product_family)
          end
          load_page(:report_pickup_return, :locals => locals)
        end

        app.get '/admin/booking/reports/pickup-return-pdf', :allowed_usergroups => ['booking_manager', 'staff'] do

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

          content_type 'application/pdf'
          pdf = ::Yito::Model::Booking::Pdf::PickupReturn.new(from, to).build.render

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

          @reservations = condition.build_datamapper(BookingDataSystem::Booking).all(
              :order => [:date_from, :time_from])
          locals = {}
          locals.store(:booking_reservation_starts_with,
                       SystemConfiguration::Variable.get_value('booking.reservation_starts_with', :dates).to_sym)
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

          @reservations = condition.build_datamapper(BookingDataSystem::Booking).all(
              :order => [:date_from, :time_from])
          locals = {}
          locals.store(:booking_reservation_starts_with,
                       SystemConfiguration::Variable.get_value('booking.reservation_starts_with', :dates).to_sym)
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

          locals = {}
          locals.store(:booking_reservation_starts_with,
                       SystemConfiguration::Variable.get_value('booking.reservation_starts_with', :dates).to_sym)
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
          locals.store(:booking_reservation_starts_with,
                       SystemConfiguration::Variable.get_value('booking.reservation_starts_with', :dates).to_sym)
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