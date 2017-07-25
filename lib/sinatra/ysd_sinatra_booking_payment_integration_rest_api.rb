module Sinatra
  module YSD
    #
    # Payment Sinatra REST API
    #
    module BookingPaymentIntegrationRESTApi

      def self.registered(app)

        #
        # Notifies a payment
        #
        app.post '/api/booking/integration/charge', :allowed_usergroups => ['booking_charge_supplier','staff']  do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))

          # Get the attributes
          begin
            date = DateTime.strptime(data['date'], '%Y-%m-%d %H:%M:%S') if data.has_key?('date')
          rescue
            date = nil
            logger.error("date not valid #{data['date']}")
          end
          reference = data['reference'] if data.has_key?('reference')
          amount = data['amount'] if data.has_key?('amount')
          currency = data['currency'] if data.has_key?('currency')
          origin = data['origin'] if data.has_key?('origin')
          payment_method_id = data['payment_method_id'] if data.has_key?('payment_method_id')
          
          if reference.nil? or amount.nil? or currency.nil? or date.nil? or payment_method_id.nil? or origin.nil?
            halt 422, {error: "Invalid data. The request must contain the following attributes: reference, amount, currency, origin, date, payment_method_id"}.to_json
          end

          # Get the source
          unless source = BookingDataSystem::Booking.get(reference.to_i)
            source = ::Yito::Model::Order::Order.get(reference.to_i)
          end

          if source
            begin
              Payments::Charge.transaction do
                # Create the charge
                charge = Payments::Charge.create({date: date,
                                                  amount: amount, currency: currency, origin: origin,
                                                  payment_method_id: payment_method_id, status: :done })
                # Create the source-charge relationship
                if source.is_a?(BookingDataSystem::Booking)
                  booking_charge = BookingDataSystem::BookingCharge.create({charge_id: charge.id, booking_id: source.id})
                elsif source.is_a?(::Yito::Model::Order::Order)
                  order_charge = ::Yito::Model::Order::OrderCharge.create({charge_id: charge.id, order_id: source.id})
                end
                # Update the source
                source.total_paid += charge.amount
                source.total_pending -= charge.amount
                if (source.total_pending == 0)
                  source.payment_status = :total unless source.payment_status == :total
                else
                  source.payment_status = :deposit unless source.payment_status == :deposit
                end
                if source.status == :pending_confirmation
                  source.confirm
                else
                  source.save
                end
              end
            rescue DataMapper::SaveFailureError => error
              content :json
              halt 422, {error: error.resource.errors.full_messages}.to_json
            end
          else
            status 400
            body "Reference not found"
          end

        end

      end

    end
  end
end