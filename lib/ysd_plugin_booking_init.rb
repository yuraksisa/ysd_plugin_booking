require 'ysd-plugins' unless defined?Plugins::Plugin
require 'ysd_plugin_booking_extension'

Plugins::SinatraAppPlugin.register :booking do

   name=        'booking'
   author=      'yurak sisa'
   description= 'Booking integration'
   version=     '0.1'
   hooker       Huasi::BookingExtension
   sinatra_helper Sinatra::BookingHelpers
   sinatra_extension Sinatra::YSD::Booking
   sinatra_extension Sinatra::YSD::BookingManagement
   sinatra_helper Sinatra::YSD::BookingManagementRESTApiHelper
   sinatra_extension Sinatra::YSD::BookingManagementRESTApi
   sinatra_extension Sinatra::YSD::RestaurantBooking
   sinatra_extension Sinatra::YSD::RestaurantBookingManagement   
   sinatra_extension Sinatra::YSD::RestaurantBookingManagementRESTApi
   sinatra_extension Sinatra::YSD::SimpleBookingManagement   
   sinatra_extension Sinatra::YSD::SimpleBookingManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingProductFamilyManagementRESTApi   
   sinatra_extension Sinatra::YitoExtension::BookingCatalogManagement
   sinatra_extension Sinatra::YitoExtension::BookingCatalogManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingCategoryManagement
   sinatra_extension Sinatra::YitoExtension::BookingCategoryManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingExtraManagement
   sinatra_extension Sinatra::YitoExtension::BookingExtraManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingItemManagement
   sinatra_extension Sinatra::YitoExtension::BookingItemManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingPickupReturnPlaceDefinitionsManagement
   sinatra_extension Sinatra::YitoExtension::BookingPickupReturnPlaceDefinitionsManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingPickupReturnPlacesManagement
   sinatra_extension Sinatra::YitoExtension::BookingPickupReturnPlacesManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingCustomers

end