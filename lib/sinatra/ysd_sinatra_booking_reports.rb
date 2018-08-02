module Sinatra
  module YitoExtension
    #
    # Reports
    #
    module BookingReports

      def self.registered(app)


        #
        # Category traslation page
        #
        app.get "/admin/booking/reports/detailed-picked-up-products", :allowed_usergroups => ['booking_manager', 'staff'] do

          from = DateTime.now
          if params.has_key?('from')
            begin
              from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date from is not valid #{params[:from]}")
            end
          end

          to = from
          if params.has_key?('to')
            begin
              to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date to is not valid #{params[:to]}")
            end
          end

          @data = BookingDataSystem::Booking.detailed_picked_up_products(from.to_date, to.to_date)

          load_page(:report_detailed_picked_up_products)


        end

        app.get "/admin/booking/reports/detailed-picked-up-products-csv", :allowed_usergroups => ['booking_manager', 'staff'] do

          from = DateTime.now
          if params.has_key?('from')
            begin
              from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date from is not valid #{params[:from]}")
            end
          end

          to = from
          if params.has_key?('to')
            begin
              to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date to is not valid #{params[:to]}")
            end
          end

          @data = BookingDataSystem::Booking.detailed_picked_up_products(from.to_date, to.to_date)

          result = "localizador;fecha inicio;fecha fin;marca/modelo/color;matrícula;nombre usuario;documento usuario;permiso conducir;dirección"
          result << "\n"
          @data.each do |reservation|
            result << "#{reservation.id};#{reservation.date_from.strftime('%Y-%m-%d')} #{reservation.time_from};#{reservation.date_to.strftime('%Y-%m-%d')} #{reservation.time_to};"
            result << "#{reservation.booking_item_stock_model};#{reservation.booking_item_stock_plate};#{reservation.driver_name} #{reservation.driver_surname};"
            result << "#{reservation.driver_document_id};#{reservation.driver_driving_license_number};"
            result << "#{reservation.street} #{reservation.number} #{reservation.complement} #{reservation.city} #{reservation.state} #{reservation.country} #{reservation.zip}"
            result << "\n"
          end

          suffix = (to.to_date == from.to_date) ? to.strftime('%Y-%m-%d') : "#{from.strftime('%Y-%m-%d')}-#{to.strftime('%Y-%m-%d')}"

          content_type 'text/csv'
          attachment "pickup-return-#{suffix}.csv"
          body result.force_encoding("utf-8")

        end

        #
        # Reservation summary : Started reservations between date interval
        #
        app.get "/admin/booking/reports/finances-started-reservations", :allowed_usergroups => ['booking_manager', 'staff'] do

          from = DateTime.now
          if params.has_key?('from')
            begin
              from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date from is not valid #{params[:from]}")
            end
          end

          to = from
          if params.has_key?('to')
            begin
              to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date to is not valid #{params[:to]}")
            end
          end

          @data = BookingDataSystem::Booking.finances_started_reservations(from.to_date, to.to_date)

          load_page(:report_finances_started_reservations)


        end

        app.get "/admin/booking/reports/finances-started-reservations-csv", :allowed_usergroups => ['booking_manager', 'staff'] do

          from = DateTime.now
          if params.has_key?('from')
            begin
              from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date from is not valid #{params[:from]}")
            end
          end

          to = from
          if params.has_key?('to')
            begin
              to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date to is not valid #{params[:to]}")
            end
          end

          @data = BookingDataSystem::Booking.finances_started_reservations(from.to_date, to.to_date)

          result = "localizador;matrícula;modelo;conductor;fecha inicio;fecha fin;notas;importe total contrato"
          result << "\n"
          @data.each do |reservation|
            result << "#{reservation.id};#{reservation.booking_item_stock_plate};#{reservation.booking_item_stock_model};#{reservation.driver_name} #{reservation.driver_surname};"
            result << "#{reservation.date_from.strftime('%Y-%m-%d')} #{reservation.time_from};#{reservation.date_to.strftime('%Y-%m-%d')} #{reservation.time_to};"
            result << reservation.notes
            result << "#{'%.2f' % reservation.total_cost}"
            result << "\n"
          end

          suffix = (to.to_date == from.to_date) ? to.strftime('%Y-%m-%d') : "#{from.strftime('%Y-%m-%d')}-#{to.strftime('%Y-%m-%d')}"

          content_type 'text/csv'
          attachment "finances-#{suffix}.csv"
          body result.force_encoding("utf-8")

        end
        
        #
        # Reservation summary : Ended reservations between date interval
        #
        app.get "/admin/booking/reports/finances-finished-reservations", :allowed_usergroups => ['booking_manager', 'staff'] do

          from = DateTime.now
          if params.has_key?('from')
            begin
              from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date from is not valid #{params[:from]}")
            end
          end

          to = from
          if params.has_key?('to')
            begin
              to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date to is not valid #{params[:to]}")
            end
          end

          @data = BookingDataSystem::Booking.finances_finished_reservations(from.to_date, to.to_date)

          load_page(:report_finances_finished_reservations)


        end

        app.get "/admin/booking/reports/finances-finished-reservations-csv", :allowed_usergroups => ['booking_manager', 'staff'] do

          from = DateTime.now
          if params.has_key?('from')
            begin
              from = DateTime.strptime(params[:from], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date from is not valid #{params[:from]}")
            end
          end

          to = from
          if params.has_key?('to')
            begin
              to = DateTime.strptime(params[:to], '%Y-%m-%d')
            rescue
              logger.error("pickup/return date to is not valid #{params[:to]}")
            end
          end

          @data = BookingDataSystem::Booking.finances_finished_reservations(from.to_date, to.to_date)

          result = "localizador;matrícula;modelo;conductor;fecha inicio;fecha fin;notas;importe total contrato"
          result << "\n"
          @data.each do |reservation|
            result << "#{reservation.id};#{reservation.booking_item_stock_plate};#{reservation.booking_item_stock_model};#{reservation.driver_name} #{reservation.driver_surname};"
            result << "#{reservation.date_from.strftime('%Y-%m-%d')} #{reservation.time_from};#{reservation.date_to.strftime('%Y-%m-%d')} #{reservation.time_to};"
            result << reservation.notes
            result << "#{'%.2f' % reservation.total_cost}"
            result << "\n"
          end

          suffix = (to.to_date == from.to_date) ? to.strftime('%Y-%m-%d') : "#{from.strftime('%Y-%m-%d')}-#{to.strftime('%Y-%m-%d')}"

          content_type 'text/csv'
          attachment "finances-#{suffix}.csv"
          body result.force_encoding("utf-8")

        end

      end

    end
  end
end  