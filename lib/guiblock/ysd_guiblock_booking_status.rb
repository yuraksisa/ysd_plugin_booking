module GuiBlock
  
  #
  # Manages booking status
  #
  class BookingStatus

    #
    # Information
    #
    def element_info(context={})
      app = context[:app]
      {:id => 'booking_status', :description => "#{app.t.guiblock.booking_status.description}"} 
    end

    #
    # Edit Form tab
    #
    def element_form_tab(context={}, aspect_model)
      app = context[:app]

      info = element_info(context)
      app.render_tab("#{info[:id]}_form", info[:description])

    end

    #
    # Form
    #
    def element_form(context={}, aspect_model)

      app = context[:app]

      renderer = ::UI::FieldSetRender.new('publishing', app)      
      renderer.render('form', 'em', {:publishing_buttons => publishing_buttons(context)}) 

    end

    #
    # Editing support
    #
    def element_form_extension(context={}, aspect_model)
    
      app = context[:app]

      renderer = ::UI::FieldSetRender.new('publishing', app)      
      renderer.render('formextension', 'em')      

    end   

    private

    def publishing_buttons(context={})

     app = context[:app]

      actions = []

      publishable.publishing_actions.each do |pub_action| 
        if url = case pub_action
                when ContentManagerSystem::PublishingAction::CONFIRM
                   "/content/confirm/#{publishable.key}"
                when ContentManagerSystem::PublishingAction::VALIDATE
                   "/content/validate/#{publishable.key}"
                when ContentManagerSystem::PublishingAction::PUBLISH
                   "/content/publish/#{publishable.key}"
                when ContentManagerSystem::PublishingAction::BAN
                   "/content/ban/#{publishable.key}"
                when ContentManagerSystem::PublishingAction::ALLOW
                  "/content/allow/#{publishable.key}"
              end
          actions << {:id => pub_action.id, 
                      :title => app.t.publishing.action[pub_action.id.downcase.to_sym], 
                      :text => app.t.publishing.action[pub_action.id.downcase.to_sym], 
                      :action_method => :POST, 
                      :action_url => url, 
                      :confirm_message => app.t.guiblock.publishing[pub_action.id.downcase.to_sym].message,
                      :class=>"publishing-button publishing-button-#{pub_action.id.downcase}"}
        end
      end

      buttons = ''
      actions.each do |action|
        buttons << app.render_element_action_button(action)
      end

      return buttons

    end



  end
end