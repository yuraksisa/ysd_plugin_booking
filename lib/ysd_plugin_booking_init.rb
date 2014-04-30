require 'ysd-plugins' unless defined?Plugins::Plugin
require 'ysd_plugin_booking_extension'

Plugins::SinatraAppPlugin.register :booking do

   name=        'booking'
   author=      'yurak sisa'
   description= 'Booking integration'
   version=     '0.1'
   hooker       Huasi::BookingExtension
   sinatra_extension Sinatra::YSD::Booking
   sinatra_extension Sinatra::YSD::BookingManagement
   sinatra_extension Sinatra::YSD::BookingManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingCategoryManagement
   sinatra_extension Sinatra::YitoExtension::BookingCategoryManagementRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingItemManagement
   sinatra_extension Sinatra::YitoExtension::BookingItemManagementRESTApi

end