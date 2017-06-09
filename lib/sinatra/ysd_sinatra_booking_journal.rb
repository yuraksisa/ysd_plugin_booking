module Sinatra
  module YitoExtension
    module BookingJournal
      def self.registered(app)

        #
        # Journal
        #
        app.get '/admin/booking/journal' do

           @calendar = ::Yito::Model::Calendar::Calendar.first(name: 'booking_journal')

           load_page(:booking_journal)

        end

      end
    end
  end
end