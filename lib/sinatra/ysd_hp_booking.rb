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
        addon_journal = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_journal)
        addon_tryton = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_tryton)
        addon_simple_invoicing = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_simple_invoicing)
        addon_sales_channels = RequestStore.store[:mybooking_addons].include?(:mybooking_addon_sales_channels)
      else
        addon_crm = (settings.respond_to?(:mybooking_addon_crm) ? settings.mybooking_addon_crm : false)
        addon_finances = (settings.respond_to?(:mybooking_addon_finances) ? settings.mybooking_addon_finances : false)
        addon_massive_price_adjust = (settings.respond_to?(:mybooking_addon_massive_price_adjust) ? settings.mybooking_addon_massive_price_adjust : false)
        addon_offer_promotion_code = (settings.respond_to?(:mybooking_addon_offer_promotion_code) ? settings.mybooking_addon_offer_promotion_code : false)
        addon_journal = (settings.respond_to?(:mybooking_addon_journal) ? settings.mybooking_addon_journal : false)
        addon_tryton = (settings.respond_to?(:mybooking_addon_tryton) ? settings.mybooking_addon_tryton : false)
        addon_simple_invoicing = (settings.respond_to?(:mybooking_addon_simple_invoicing) ? settings.mybooking_addon_simple_invoicing : false)
        addon_sales_channels = (settings.respond_to?(:mybooking_addon_sales_channels) ? settings.mybooking_addon_sales_channels : false) 
      end

      {addon_crm: addon_crm,
       addon_finances: addon_finances,
       addon_massive_price_adjust: addon_massive_price_adjust,
       addon_offer_promotion_code: addon_offer_promotion_code,
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
    # Get the booking catalog template
    # 
    #   - From the parameters
    #   - From the default template
    #   - The first catalog
    # 
    def catalog_template(catalog=nil)
    
        booking_js = if catalog
                       ContentManagerSystem::Template.find_by_name(catalog.rates_template_code)
                     else
                       ContentManagerSystem::Template.find_by_name('booking_js')
                     end
    end

  end
end
