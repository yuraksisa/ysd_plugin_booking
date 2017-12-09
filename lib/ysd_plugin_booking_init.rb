require 'ysd-plugins' unless defined?Plugins::Plugin
require 'ysd_plugin_booking_extension'

Plugins::SinatraAppPlugin.register :booking do

   name=        'booking'
   author=      'yurak sisa'
   description= 'Booking integration'
   version=     '0.1'
   hooker       Huasi::BookingExtension
   sinatra_helper Sinatra::BookingHelpers
   sinatra_helper Sinatra::YSD::BookingActivitiesHelper
   sinatra_extension Sinatra::YSD::Booking
   sinatra_extension Sinatra::YSD::BookingActivities
   sinatra_extension Sinatra::YitoExtension::BookingJournal
   sinatra_extension Sinatra::YSD::BookingManagement
   sinatra_helper Sinatra::YSD::BookingManagementRESTApiHelper
   sinatra_extension Sinatra::YSD::BookingReports
   sinatra_extension Sinatra::YSD::BookingPlanning
   sinatra_extension Sinatra::YSD::BookingOccupation
   sinatra_extension Sinatra::YSD::BookingBilling
   sinatra_extension Sinatra::YitoExtension::BookingNewReservation
   sinatra_extension Sinatra::YitoExtension::BookingNewReservationRESTApi
   sinatra_helper Sinatra::YitoExtension::BookingNewReservationRESTApiHelper
   sinatra_extension Sinatra::YSD::BookingManagementRESTApi
   sinatra_extension Sinatra::YSD::RestaurantBooking
   sinatra_extension Sinatra::YSD::RestaurantBookingManagement   
   sinatra_extension Sinatra::YSD::RestaurantBookingManagementRESTApi
   sinatra_extension Sinatra::YSD::SimpleBookingManagement   
   sinatra_extension Sinatra::YSD::SimpleBookingManagementRESTApi
   sinatra_extension Sinatra::YSD::BookingPlannedActivitiesManagement
   sinatra_extension Sinatra::YSD::BookingPaymentIntegrationRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingProductFamilyManagementRESTApi   
   sinatra_extension Sinatra::YitoExtension::BookingCatalogManagement
   sinatra_extension Sinatra::YitoExtension::BookingCatalogManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingCategoryManagement
   sinatra_extension Sinatra::YitoExtension::BookingCategoryManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingExtraManagement
   sinatra_extension Sinatra::YitoExtension::BookingExtraManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingItemManagement
   sinatra_extension Sinatra::YitoExtension::BookingItemManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingActivityManagement
   sinatra_extension Sinatra::YitoExtension::BookingActivityManagementRESTApi 
   sinatra_extension Sinatra::YitoExtension::BookingPrereservationManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingPickupReturnPlaceDefinitionsManagement
   sinatra_extension Sinatra::YitoExtension::BookingPickupReturnPlaceDefinitionsManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingPickupReturnPlacesManagement
   sinatra_extension Sinatra::YitoExtension::BookingPickupReturnPlacesManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingRentalLocationsManagement
   sinatra_extension Sinatra::YitoExtension::BookingRentalLocationsManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingTranslation
   sinatra_extension Sinatra::YitoExtension::BookingTranslationRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingReports
end