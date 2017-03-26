module Sinatra
  module YitoExtension
    module BookingCategoryManagement

      def self.registered(app)
        #
        # Booking categories page
        #
        app.get '/admin/booking/booking-categories/?*', :allowed_usergroups => ['booking_manager','staff'] do 

          # TODO multi-tenant
          @show_translations = settings.multilanguage_site
          locals = {:booking_category_page_size => 20, :types => ::Yito::Model::Booking::BookingCategory.types}
          load_em_page :booking_categories_management, 
                       :bookingcategory, 
                       false, :locals => locals

        end

      end

    end
  end
end
