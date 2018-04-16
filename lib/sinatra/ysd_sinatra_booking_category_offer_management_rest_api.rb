module Sinatra
  module YitoExtension
    module BookingCategoryOfferManagementRESTApi

      def self.registered(app)

        #
        # Query booking offers
        #
        ["/api/booking-offers","/api/booking-offers/page/:page"].each do |path|

          app.post path, :allowed_usergroups => ['booking_manager', 'rates_manager', 'staff']  do

            page = params[:page].to_i || 1
            limit = 20
            offset = (page-1) * 20

            conditions = {}

            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))
              if search_request.has_key?('search') and !search_request['search'].empty?
                conditions = Conditions::Comparison.new(:id, '$eq', search_request['search'].to_i)
                total = conditions.build_datamapper(::Yito::Model::Booking::BookingCategoryOffer).all.count
                data = conditions.build_datamapper(::Yito::Model::Booking::BookingCategoryOffer).all(:limit => limit, :offset => offset)
              else
                data  = ::Yito::Model::Booking::BookingCategoryOffer.all(:limit => limit, :offset => offset)
                total = ::Yito::Model::Booking::BookingCategoryOffer.count
              end
            else
              data  = ::Yito::Model::Booking::BookingCategoryOffer.all(:limit => limit, :offset => offset)
              total = ::Yito::Model::Booking::BookingCategoryOffer.count
            end

            data_json = data.to_json(relationships: {discount: {}, booking_categories: {only: [:code, :name]}})
            total_json = total.to_json

            content_type :json
            "{\"data\": #{data_json}, \"summary\":{ \"total\": #{total_json} }}"
            #{:data => data, :summary => {:total => total}}.to_json

          end

        end

        #
        # Get booking offers
        #
        app.get "/api/booking-offers", :allowed_usergroups => ['booking_manager', 'rates_manager', 'staff']  do

          data = ::Yito::Model::Booking::BookingCategoryOffer.all

          status 200
          content_type :json
          data.to_json(relationships: {discount: {}, booking_categories: {only: [:code, :name]}})

        end

        #
        # Get a discount
        #
        app.get "/api/booking-offer/:id", :allowed_usergroups => ['booking_manager', 'rates_manager', 'staff']  do

          data = ::Yito::Model::Rates::Discount.get(params[:id].to_i)

          status 200
          content_type :json
          data.to_json

        end

        #
        # Create a new discount
        #
        app.post "/api/booking-offer", :allowed_usergroups => ['booking_manager', 'rates_manager', 'staff']  do

          data_request = body_as_json(::Yito::Model::Booking::BookingCategoryOffer)
          data = ::Yito::Model::Booking::BookingCategoryOffer.new
          # Offer
          data.discount = ::Yito::Model::Rates::Discount.new
          data.discount.attributes = data_request[:discount]
          # Affected categories
          data_request[:booking_categories].each do |category|
            if (!data.booking_categories.any? {|item| item.code == category} and booking_category = ::Yito::Model::Booking::BookingCategory.get(category))
              data.booking_categories << booking_category
            end
          end
          data.save

          status 200
          content_type :json
          data.to_json(relationships: {discount: {}, booking_categories: {only: [:code, :name]}})

        end

        #
        # Updates a discount
        #
        app.put "/api/booking-offer", :allowed_usergroups => ['booking_manager', 'rates_manager', 'staff']  do

          data_request = body_as_json(::Yito::Model::Booking::BookingCategoryOffer)

          if data = ::Yito::Model::Booking::BookingCategoryOffer.get(data_request.delete(:id).to_i)
            if data_request[:discount]
              data.discount ||= ::Yito::Model::Rates::Discount.new
              data.discount.attributes = data_request[:discount]
            end
            if data_request.has_key?(:booking_categories) and data_request[:booking_categories].is_a?(Array)
              # Remove existing and not selected booking categories
              data.offer_booking_categories.all(conditions: {'booking_category_code'.to_sym.not => data_request[:booking_categories] }).destroy
              # Add not existing booking categories
              data_request[:booking_categories].each do |category|
                if (!data.booking_categories.any? {|item| item.code == category} and booking_category = ::Yito::Model::Booking::BookingCategory.get(category))
                  data.booking_categories << booking_category
                end
              end
            end
            data.save
            content_type :json
            data.to_json(relationships: {discount: {}, booking_categories: {only: [:code, :name]}})
          else
            status 404
          end

        end

        #
        # Deletes a discount
        #
        app.delete "/api/booking-offer", :allowed_usergroups => ['booking_manager', 'rates_manager', 'staff']  do

          data_request = body_as_json(::Yito::Model::Booking::BookingCategoryOffer)

          result = false
          key = data_request.delete(:id).to_i

          data = ::Yito::Model::Booking::BookingCategoryOffer.get(key)
          unless data.nil?
            ::Yito::Model::Booking::BookingCategoryOffer.transaction do
              data.discount.destroy
              data.offer_booking_categories.destroy
              data.destroy
            end
          end

          content_type :json
          result.to_json


        end


      end

    end
  end
end