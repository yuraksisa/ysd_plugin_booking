require 'ui/ysd_ui_entity_aspect_render' unless defined?UI::EntityAspectRender

module CMSRenders

  #
  # Activity Render
  #
  class ActivityRender
    
     attr_reader :activity
     attr_reader :context
     attr_reader :display
    
      def initialize(activity, context, display=nil)       
        @activity = if context.respond_to?(:session) and 
                       activity.respond_to?(:translate)
                     activity.translate(activity.session[:locale])
                   else
                     activity
                   end
        @context = context       
        @display = display 
      end
     
      def render(locals={}, opts=[])
        
        result = ''

        if activity_template_path = find_template
        
         template = Tilt.new(activity_template_path)
         
         activity_locals = {}
         activity_locals.merge!(locals) unless locals.nil?
         activity_locals.merge!(activity_extensions)
         activity_locals.merge!(activity_complements)
         activity_locals.merge!(activity_blocks)
         activity_locals.merge!({:element => activity, :activity => activity})

         result = template.render(context, activity_locals)
        
         if String.method_defined?(:force_encoding)
           result.force_encoding('utf-8')
         end

        else
          puts "Template not found render-activity.erb"
        end

        return result

      end

      private
      
      #
      # Get the activity extensions (defined in plugins)
      #
      def activity_extensions
        
        activity_action = ''
        activity_not_owner_action = ''
        activity_data = ''
        activity_action_extension = ''
        activity_not_owner_action_extension = ''

        activity_action << context.call_hook(:activity_action, {:app => context}, activity)
        activity_not_owner_action << context.call_hook(:activity_not_owner_action, {:app => context}, activity)
        activity_data << context.call_hook(:activity, {:app => context}, activity)
        activity_action_extension << context.call_hook(:activity_action_extension, {:app => context}, activity)
        activity_not_owner_action_extension << context.call_hook(:activity_not_owner_action_extension, {:app => context}, activity)

        if String.method_defined?(:force_encoding)
          activity_action.force_encoding('utf-8')
          activity_not_owner_action.force_encoding('utf-8')
          activity_data.force_encoding('utf-8')
          activity_action_extension.force_encoding('utf-8')
          activity_not_owner_action_extension.force_encoding('utf-8')        
        end

        complements = {}
        complements.store(:activity_action, activity_action)
        complements.store(:activity_not_owner_action, activity_not_owner_action)
        complements.store(:activity_data, activity_data)
        complements.store(:activity_action_extension, activity_action_extension)
        complements.store(:activity_not_owner_action_extension, activity_not_owner_action_extension)

        return complements

      end
      
      #
      # Get the activity complements (defined on aspects)
      #
      def activity_complements

       context.render_entity_aspects(activity, :activity)

      end
      
      #
      # Get the blocks configured on the activity regions
      #
      def activity_blocks
        
        result = {}

        blocks_hash = ContentManagerSystem::Block.active_blocks(
          Themes::ThemeManager.instance.selected_theme,
          Plugins::Plugin.plugin_invoke(:booking, :apps_regions, context),
          context.user,
          context.request.path_info,
          nil)

        blocks_hash.each do |region, blocks|
          result[region.to_sym] = []
          blocks.each do |block|
            block_render = CMSRenders::BlockRender.new(block, context).render || ''
            if String.method_defined?(:force_encoding)
              block_render.force_encoding('utf-8')
            end
            result[block.region.to_sym].push({:id => block.name, 
              :title => block.title, :body => block_render}) 
          end
        end

        return result

      end


      # Finds the template to render the content
      #
      # @param [String] resource_name
      #   The name of the template
      #
      def find_template
         
         template_name = "render-activity"
         template_name << "-#{display}" unless display.nil?

         # Search in theme path
         activity_template_path = Themes::ThemeManager.instance.selected_theme.resource_path("#{template_name}.erb",'template','activity') 
         
         # Search in the project
         if not activity_template_path
           path = context.get_path(template_name)                            
           activity_template_path = path if not path.nil? and File.exist?(path)
         end
         
         return activity_template_path
         
      end   
     
      
    end #ActivityRender
end #BookingRenders