module Sinatra
  module YitoExtension
    module BookingRentalLocationsManagementRESTApi

      def self.registered(app)

        #
        # Query booking-rental-location
        #
        ["/api/booking-rental-locations","/api/booking-rental-locations/page/:page"].each do |path|

          app.post path do

            page = [params[:page].to_i, 1].max
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:name.asc]}

            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))
              search_text = search_request['search']
              conditions = Conditions::Comparison.new(:name, '$like', "%#{search_text}%")

              total = conditions.build_datamapper(::Yito::Model::Booking::RentalLocation).all.count
              data = conditions.build_datamapper(::Yito::Model::Booking::RentalLocation).all(offset_order_query)
            else
              data,total  = ::Yito::Model::Booking::RentalLocation.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json

          end

        end

        #
        # Get booking-rental-location
        #
        app.get "/api/booking-rental-locations" do

          data = ::Yito::Model::Booking::RentalLocation.all()

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking-rental-location
        #
        app.get "/api/booking-rental-location/:id" do

          data = ::Yito::Model::Booking::RentalLocation.get(params[:id].to_i)

          status 200
          content_type :json
          data.to_json

        end

        #
        # Create a booking-rental-location
        #
        app.post "/api/booking-rental-location" do

          data_request = body_as_json(::Yito::Model::Booking::RentalLocation)
          data_request.store(:address, {}) unless data_request.has_key?(:address)
          data = ::Yito::Model::Booking::RentalLocation.create(data_request)

          status 200
          content_type :json
          data.to_json

        end

        #
        # Updates a booking-rental-location
        #
        app.put "/api/booking-rental-location" do

          data_request = body_as_json(::Yito::Model::Booking::RentalLocation)

          if data = ::Yito::Model::Booking::RentalLocation.get(data_request.delete(:code))
            data.attributes=data_request
            data.save
          end

          content_type :json
          data.to_json

        end

        #
        # Deletes a booking-rental-location
        #
        app.delete "/api/booking-rental-location" do

          data_request = body_as_json(::Yito::Model::Booking::RentalLocation)

          key = data_request.delete(:code)

          if data = ::Yito::Model::Booking::RentalLocation.get(key)
            data.destroy
          end

          content_type :json
          true.to_json

        end

      end
    end
  end
end