module Sinatra
  module YSD
    #
    # Sinatra extension to manage bookings
    #
    module BookingActivities

      def self.registered(app) 
        
        #
        # Add an activity to the shopping cart
        #
        app.post '/p/activity/add-to-shopping-cart' do 

          activity_id = params[:activity_id]
          date = DateTime.strptime(params[:date],'%Y-%m-%d')
          time = params[:turn]
          quantity_rate_1 = params[:quantity_rate_1].to_i
          quantity_rate_2 = params[:quantity_rate_2].to_i
          quantity_rate_3 = params[:quantity_rate_3].to_i

          if activity = ::Yito::Model::Booking::Activity.get(activity_id)
            
            # Load or build the shopping cart
            @shopping_cart = nil
            
            if session[:shopping_cart_id]
              @shopping_cart = ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
            end

            unless @shopping_cart
              @shopping_cart = ::Yito::Model::Order::ShoppingCart.new(:creation_date => DateTime.now)
            end

            # Appends items
            if !quantity_rate_1.nil? and quantity_rate_1 > 0
              @shopping_cart.add_item(date, 
                                      time, 
                                      activity.code, 
                                      activity.name,
                                      1,
                                      quantity_rate_1,
                                      activity.rates(date)[1][1],
                                      activity.price_1_description)
            end

            if !quantity_rate_2.nil? and quantity_rate_2 > 0
              @shopping_cart.add_item(date, 
                                      time, 
                                      activity.code, 
                                      activity.name,
                                      2,
                                      quantity_rate_2,
                                      activity.rates(date)[2][1],
                                      activity.price_2_description) 
            end

            if !quantity_rate_3.nil? and quantity_rate_3 > 0
              @shopping_cart.add_item(date, 
                                      time, 
                                      activity.code, 
                                      activity.name,
                                      3,
                                      quantity_rate_3,
                                      activity.rates(date)[3][1],
                                      activity.price_3_description)               
            end

            begin
              @shopping_cart.save
            rescue DataMapper::SaveFailureError => error
              p "Error saving shopping_cart. #{@shopping_cart.inspect} #{@shopping_cart.errors.inspect}"
              raise error
            end

            if session.has_key?(:shopping_cart_id) 
              session[:shopping_cart_id] = @shopping_cart.id if session[:shopping_cart_id] != @shopping_cart.id
            else
              session[:shopping_cart_id] = @shopping_cart.id
            end

            redirect "/p/activities/shopping-cart"

          else
            redirect "/p/activity/#{activity_id}"
          end 

        end       
        
        #
        # Remove an item from the shopping cart
        #
        app.post '/p/activity/remove-to-shopping-cart' do  
        
          if shopping_cart_item = ::Yito::Model::Order::ShoppingCartItem.get(params[:id])
            shopping_cart_item.shopping_cart.remove_item(shopping_cart_item.date,
                                                         shopping_cart_item.time,
                                                         shopping_cart_item.item_id)
            flash[:notice] = 'Producto eliminado del carrito'
          end

          redirect "/p/activities/shopping-cart" 
        
        end
        
        #
        # Shopping cart checkout
        #
        app.post '/p/activities/shopping-cart-checkout/?*' do

          @shopping_cart = if session[:shopping_cart_id]
                             ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
                           else
                             ::Yito::Model::Order::ShoppingCart.new
                           end

          @shopping_cart = ::Yito::Model::Order::ShoppingCart.new if @shopping_cart.nil?

          load_page(:reservation_activities_checkout,{cache: false})
        end
        
        #
        # Creates an order from the shopping cart
        #
        app.post '/p/activities/shopping-cart-order/?*' do

          if session[:shopping_cart_id]
            @shopping_cart = ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
            if @shopping_cart 
              @order = ::Yito::Model::Order::Order.create_from_shopping_cart(@shopping_cart)
              @order.comments = params[:comments]
              @order.customer_name = params[:customer_name]
              @order.customer_surname = params[:customer_surname]
              @order.customer_email = params[:customer_email]
              @order.customer_phone = params[:customer_phone]
              @order.customer_language = session[:locale] || 'es'
              @order.init_user_agent_data(request.env["HTTP_USER_AGENT"])
              allow_deposit_payment = SystemConfiguration::Variable.get_value('order.allow_deposit_payment','false').to_bool
              deposit = SystemConfiguration::Variable.get_value('order.deposit').to_i
              if allow_deposit_payment and deposit > 0
                @order.reservation_amount = (@order.total_cost * deposit / 100).round
              end
              @order.save
              @shopping_cart.destroy
              session.delete(:shopping_cart_id) 
              redirect "/p/myorder/#{@order.free_access_id}"
            else
              status 404
            end
          else
            status 404
          end

        end

        #
        # Show the activities shopping cart
        #
        app.get '/p/activities/shopping-cart/?*' do 

            @shopping_cart = if session[:shopping_cart_id]
                               ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
                             else
                               ::Yito::Model::Order::ShoppingCart.new
                             end

            @shopping_cart = ::Yito::Model::Order::ShoppingCart.new if @shopping_cart.nil?

            load_page(:reservation_activities_shopping_cart, {cache: false})

        end

        #
        # Show the activities
        #
        app.get '/p/activities/?*' do 

          @activities = ::Yito::Model::Booking::Activity.all(active: true)
          load_page(:reservation_activities)

        end
        
        #
        # Show an activity
        #
        app.get '/p/activity/:id/?*' do

          @activity = ::Yito::Model::Booking::Activity.get(params[:id])
          
          if @activity and @activity.active
            load_page(:reservation_activity)
          else
            status 404
          end

        end

      end

    end
  end
end
