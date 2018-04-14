module Sinatra
  module BookingHelpers

    #
    # Get the plan
    #
    def mybooking_plan

      booking_renting = true
      booking_activities = false
      unless mybooking_plan = RequestStore.store[:mybooking_plan]
        mybooking_plan = settings.respond_to?(:mybooking_plan) ? settings.mybooking_plan : nil
      end
      if mybooking_plan
        booking_renting = [:pro_renting, :pro_plus].include?(mybooking_plan)
        booking_activities = [:pro_activities, :pro_plus].include?(mybooking_plan)
      end

      [booking_renting, booking_activities]

    end

    #
    # Get the add-ons
    #
    def mybooking_addons

      if RequestStore.store[:mybooking_addons]
        addon_crm = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_crm)
        addon_finances = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_finances)
        addon_massive_price_adjust = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_massive_price_adjust)
        addon_offer_promotion_code = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_offer_promotion_code)
        addon_promotion_code = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_promotion_code)
        addon_offer = RequestStore.store[:mybooking_addons].include?(:mybooking_offer)
        addon_journal = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_journal)
        addon_tryton = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_tryton)
        addon_simple_invoicing = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_simple_invoicing)
        addon_sales_channels = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_sales_channels)
      else
        addon_crm = (settings.respond_to?(:mybooking_addon_crm) ? settings.mybooking_addon_crm : false)
        addon_finances = (settings.respond_to?(:mybooking_addon_finances) ? settings.mybooking_addon_finances : false)
        addon_massive_price_adjust = (settings.respond_to?(:mybooking_addon_massive_price_adjust) ? settings.mybooking_addon_massive_price_adjust : false)
        addon_offer_promotion_code = (settings.respond_to?(:mybooking_addon_offer_promotion_code) ? settings.mybooking_addon_offer_promotion_code : false)
        addon_promotion_code = (settings.respond_to?(:mybooking_addon_promotion_code) ? settings.mybooking_addon_promotion_code : false)
        addon_offer =  (settings.respond_to?(:mybooking_addon_offer) ? settings.mybooking_addon_offer : false)
        addon_journal = (settings.respond_to?(:mybooking_addon_journal) ? settings.mybooking_addon_journal : false)
        addon_tryton = (settings.respond_to?(:mybooking_addon_tryton) ? settings.mybooking_addon_tryton : false)
        addon_simple_invoicing = (settings.respond_to?(:mybooking_addon_simple_invoicing) ? settings.mybooking_addon_simple_invoicing : false)
        addon_sales_channels = (settings.respond_to?(:mybooking_addon_sales_channels) ? settings.mybooking_addon_sales_channels : false) 
      end

      {addon_crm: addon_crm,
       addon_finances: addon_finances,
       addon_massive_price_adjust: addon_massive_price_adjust,
       addon_offer_promotion_code: addon_offer_promotion_code,
       addon_offer: addon_offer,
       addon_promotion_code: addon_promotion_code,
       addon_journal: addon_journal,
       addon_tryton: addon_tryton,
       addon_simple_invoicing: addon_simple_invoicing,
       addon_sales_channels: addon_sales_channels}

    end

    #
    # Request catalog
    #
    def request_catalog

        catalog =  if params[:booking_catalog_code]
                      ::Yito::Model::Booking::BookingCatalog.get(params[:booking_catalog_code])
                   else
                      code = ::SystemConfiguration::Variable.get_value('booking.default_booking_catalog.code', nil)
                      ::Yito::Model::Booking::BookingCatalog.get(code)
                   end 
        
        unless catalog 
          catalog = ::Yito::Model::Booking::BookingCatalog.first
        end 

        return catalog

    end


    #
    # Extract pickup/return place from request
    #
    def request_pickup_return_place(data)

      pickup_place = nil
      custom_pickup_place = false
      pickup_place_customer_translation = nil
      return_place = nil
      custom_return_place = false
      return_place_customer_translation = nil
      if booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')) and
          booking_item_family.pickup_return_place
        pickup_return_places_configuration = SystemConfiguration::Variable.get_value('booking.pickup_return_places_configuration', 'list')
        if pickup_return_places_configuration == 'list'
          pickup_place = data[:pickup_place]
          custom_pickup_place = false
          return_place = data[:return_place]
          custom_return_place = false
        elsif pickup_return_places_configuration == 'value'
          pickup_place = data[:pickup_place_other]
          custom_pickup_place = false
          return_place = data[:return_place_other]
          custom_return_place = false
        elsif pickup_return_places_configuration == 'list+custom'
          custom_pickup_place = (data[:custom_pickup_place] || 'false').to_bool
          custom_return_place = (data[:custom_return_place] || 'false').to_bool
          if custom_pickup_place
            pickup_place = data[:pickup_place_other]
          else
            pickup_place = data[:pickup_place]
          end
          if custom_return_place
            return_place = data[:return_place_other]
          else
            return_place = data[:return_place]
          end
        end
        # pickup_place_customer_translation
        if custom_pickup_place
          pickup_place_customer_translation = pickup_place
        else
          booking_pickup_place = ::Yito::Model::Booking::PickupReturnPlace.first(name: pickup_place)
          pickup_place_customer_translation = booking_pickup_place ? booking_pickup_place.translate(session[:locale]).name : pickup_place
        end
        # return_place_customer_translation
        if custom_return_place
          return_place_customer_translation = return_place
        else
          booking_return_place = ::Yito::Model::Booking::PickupReturnPlace.first(name: return_place)
          return_place_customer_translation = booking_return_place ? booking_return_place.translate(session[:locale]).name : return_place
        end
      end

      [pickup_place, custom_pickup_place, pickup_place_customer_translation,
       return_place, custom_return_place, return_place_customer_translation]

    end


  end
end
