module Sinatra
  module YitoExtension
    module BookingCategoryManagement

      def self.registered(app)
        #
        # Booking categories page
        #
        app.get '/admin/booking/booking-categories/?*', :allowed_usergroups => ['booking_manager','staff'] do

          addons = mybooking_addons
          @addon_sales_channels = (addons and addons.has_key?(:addon_sales_channels) and addons[:addon_sales_channels])
          @booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          @show_translations = settings.multilanguage_site
          # Multiple rental locations
          @multiple_rental_locations = BookingDataSystem::Booking.multiple_rental_locations
          locals = {:booking_category_page_size => 20, :types => ::Yito::Model::Booking::BookingCategory.types}
          locals.store(:products_allow_deposit, SystemConfiguration::Variable.get_value('booking.products.allow_deposit', 'false').to_bool)
          load_em_page :booking_categories_management,
                       :bookingcategory, 
                       false, :locals => locals

        end

      end

    end
  end
end
