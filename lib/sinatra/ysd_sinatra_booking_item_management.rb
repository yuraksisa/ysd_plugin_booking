module Sinatra
  module YitoExtension
    module BookingItemManagement

      def self.registered(app)
        
        #
        # Booking item expenses
        #
        app.get '/admin/booking/booking-items/:id/expenses', :allowed_usergroups => ['booking_manager', 'staff'] do

          load_page :booking_item_expenses

        end  

        #
        # Edit a booking item
        #
        app.get '/admin/booking/booking-items/:id/edit', :allowed_usergroups => ['booking_manager', 'staff'] do

          if @booking_item = ::Yito::Model::Booking::BookingItem.get(params[:id])
            @addons = mybooking_addons
            @addon_fleet_maintenance = (@addons and @addons.has_key?(:addon_fleet_maintenance) and @addons[:addon_fleet_maintenance])
            @booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
            @multiple_rental_locations = BookingDataSystem::Booking.multiple_rental_locations
            if @multiple_rental_locations
              @rental_storages = ::Yito::Model::Booking::RentalStorage.all
            end  
            load_page :booking_item_edit
          else
            status 404
          end  

        end  

        #
        # Booking items page
        #
        app.get '/admin/booking/booking-items/?*', :allowed_usergroups => ['booking_manager','staff'] do

          # Add-on finances
          @addons = mybooking_addons
          @addon_finances = (@addons and @addons.has_key?(:addon_finances) and @addons[:addon_finances])
          @addon_fleet_maintenance = (@addons and @addons.has_key?(:addon_fleet_maintenance) and @addons[:addon_fleet_maintenance])
          # Item family
          @booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          # Multiple rental locations
          @multiple_rental_locations = BookingDataSystem::Booking.multiple_rental_locations

          load_em_page :booking_items_management, :bookingitem, false

        end

        #
        # Products that belongs to a category
        #
        app.get '/admin/booking/stock/:category/?*', :allowed_usergroups => ['booking_manager','staff'] do

          @items = ::Yito::Model::Booking::BookingItem.all(conditions: {category_code: params[:category], active: true},
                                                           order: [:own_property.desc, :assignable.desc, :reference])
          load_page :booking_category_stock

        end



      end

    end
  end
end
