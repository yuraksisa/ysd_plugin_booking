module Sinatra
  module YitoExtension
    module BookingRentalStoragesManagementRESTApi

      def self.registered(app)

        #
        # Query booking-rental-storage
        #
        ["/api/booking-rental-storages","/api/booking-rental-storages/page/:page"].each do |path|

          app.post path do

            page = [params[:page].to_i, 1].max
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:name.asc]}

            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))
              search_text = search_request['search']
              conditions = Conditions::Comparison.new(:name, '$like', "%#{search_text}%")

              total = conditions.build_datamapper(::Yito::Model::Booking::RentalStorage).all.count
              data = conditions.build_datamapper(::Yito::Model::Booking::RentalStorage).all(offset_order_query)
            else
              data,total  = ::Yito::Model::Booking::Rentalstorage.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json

          end

        end

        #
        # Get booking-rental-storage
        #
        app.get "/api/booking-rental-storages" do

          data = ::Yito::Model::Booking::RentalStorage.all()

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking-rental-storage
        #
        app.get "/api/booking-rental-storage/:id" do

          data = ::Yito::Model::Booking::RentalStorage.get(params[:id].to_i)

          status 200
          content_type :json
          data.to_json

        end

        #
        # Create a booking-rental-storage
        #
        app.post "/api/booking-rental-storage" do

          data_request = body_as_json(::Yito::Model::Booking::RentalStorage)
          data_request.store(:address, {}) unless data_request.has_key?(:address)
          data = ::Yito::Model::Booking::RentalStorage.create(data_request)

          status 200
          content_type :json
          data.to_json

        end

        #
        # Updates a booking-rental-storage
        #
        app.put "/api/booking-rental-storage" do

          data_request = body_as_json(::Yito::Model::Booking::RentalStorage)

          if data = ::Yito::Model::Booking::RentalStorage.get(data_request.delete(:id))
            data.attributes=data_request
            data.save
          end

          content_type :json
          data.to_json

        end

        #
        # Deletes a booking-rental-storage
        #
        app.delete "/api/booking-rental-storage" do

          data_request = body_as_json(::Yito::Model::Booking::RentalStorage)

          key = data_request.delete(:id).to_i

          p "key: #{key}"

          if data = ::Yito::Model::Booking::RentalStorage.get(key)
            p "destroy"
            data.destroy
          end

          content_type :json
          true.to_json

        end

      end
    end
  end
end