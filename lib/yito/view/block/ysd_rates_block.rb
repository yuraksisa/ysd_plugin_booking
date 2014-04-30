module Yito
  module View
  	module Block
  	  #
  	  # A block that render rates
  	  #	
  	  class RatesBlock

         def html(context={})

           app = context[:app]
           app.partial(:rates)

         end

         def jscript(context={})

           app = context[:app]
           app.partial("rates.js".to_sym)

         end

  	  end
  	end
  end
end