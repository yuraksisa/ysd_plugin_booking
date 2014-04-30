module Yito
  module View
  	module Block
  	  #
  	  # A block that render season management
  	  #	
  	  class SeasonBlock

         def html(context={})

           app = context[:app]
           app.partial(:seasons)

         end

         def jscript(context={})

           app = context[:app]
           app.partial("seasons.js".to_sym)

         end

  	  end
  	end
  end
end