module Sinatra
  module YitoExtension
    module BookingExtraManagementRESTApi

      def self.registered(app)

        #                    
        # Query booking-extra
        #
        ["/api/booking-extras","/api/booking-extras/page/:page"].each do |path|
          
          app.post path do

            page = [params[:page].to_i, 1].max  
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:code.asc]} 

            
            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))
              search_text = search_request['search']
              conditions = Conditions::JoinComparison.new('$or',
                                                          [Conditions::Comparison.new(:code, '$like', "%#{search_text}%"),
                                                           Conditions::Comparison.new(:name, '$like', "%#{search_text}%")
                                                          ])

              total = conditions.build_datamapper(::Yito::Model::Booking::BookingExtra).all.count 
              data = conditions.build_datamapper(::Yito::Model::Booking::BookingExtra).all(offset_order_query) 

            else            
              data,total  = ::Yito::Model::Booking::BookingExtra.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json

          
          end
        
        end
        
        #
        # Get booking-extra
        #
        app.get "/api/booking-extras" do

          data = if params[:all] and params[:all] == 'yes'
                   ::Yito::Model::Booking::BookingExtra.all(active: true)
                 else
                   ::Yito::Model::Booking::BookingExtra.all(active: true, web_public: true)
                 end

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get a booking-extra
        #
        app.get "/api/booking-extra/:id" do
        
          data = ::Yito::Model::Booking::BookingExtra.get(params[:code])
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a booking-extra
        #
        app.post "/api/booking-extra" do
        
          data_request = body_as_json(::Yito::Model::Booking::BookingExtra)
          booking_categories = data_request.delete(:booking_categories) 
          data = ::Yito::Model::Booking::BookingExtra.new(data_request)
          # Affected categories
          p "booking_categories: #{booking_categories.inspect}"
          if booking_categories and booking_categories.is_a?(Array)
            booking_categories.each do |category|
              if (!data.booking_categories.any? {|item| item.code == category} and booking_category = ::Yito::Model::Booking::BookingCategory.get(category))
                data.booking_categories << booking_category
              end
            end
          end
          data.save

          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a booking-extra
        #
        app.put "/api/booking-extra" do
          
          data_request = body_as_json(::Yito::Model::Booking::BookingExtra)
                              
          if data = ::Yito::Model::Booking::BookingExtra.get(data_request.delete(:code))  
            booking_categories = data_request.delete(:booking_categories)
            data.attributes=data_request  
            if booking_categories and booking_categories.is_a?(Array)
              # Remove existing and not selected booking categories
              data.booking_extra_categories.all(conditions: {'booking_category_code'.to_sym.not => booking_categories }).destroy
              # Add not existing booking categories
              booking_categories.each do |category|
                if (!data.booking_categories.any? {|item| item.code == category} and booking_category = ::Yito::Model::Booking::BookingCategory.get(category))
                  data.booking_categories << booking_category
                end
              end
            end            
            data.save
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes a booking-extra 
        #
        app.delete "/api/booking-extra" do
        
          data_request = body_as_json(::Yito::Model::Booking::BookingExtra)
          
          key = data_request.delete(:code)
          
          if data = ::Yito::Model::Booking::BookingExtra.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

      end
    end
  end
end