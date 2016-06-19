module Sinatra
  module YSD

    module BookingActivitiesHelper

      def load_activity

          @occupation = {total_occupation: 0, occupation_detail: {}}
          if session[:activity_date_id]
            @activity_date_id = session[:activity_date_id]
            if @activity_date = ::Yito::Model::Booking::ActivityDate.get(@activity_date_id)
              @occupation = @activity.occupation(@activity_date.date_from, @activity_date.time_from)
            end
          elsif session[:date] or session[:turn]
            @date = session[:date] ? Date.strptime(session[:date],'%Y-%m-%d') : nil
            @time = session[:turn] 
            if @date and !@date.nil? and @time and !@time.nil?
              @occupation = @activity.occupation(@date, @time)
            end
          end

          # Load or build the shopping cart
          @shopping_cart = nil
            
          if session[:shopping_cart_id]
            @shopping_cart = ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
          end

          unless @shopping_cart
            @shopping_cart = ::Yito::Model::Order::ShoppingCart.new(:creation_date => DateTime.now)
          end       

          if @activity and @activity.active
            load_page(:reservation_activity, {cache: false})
          else
            status 404
          end
      end

    end 

    #
    # Sinatra extension to manage bookings
    #
    module BookingActivities

      def self.registered(app) 
        
        #
        # Load an activity (by its alias)
        #
        app.get /^[^.]*$/ do
          
          preffixes = Plugins::Plugin.plugin_invoke_all('ignore_path_prefix_cms', {:app => self})
          if request.path_info.empty? or request.path_info.start_with?(*preffixes)
            pass
          end

          # Query activity
          if @activity = ::Yito::Model::Booking::Activity.first(:alias => request.path_info)
            session.delete(:activity_date_id)
            session.delete(:date)
            session.delete(:turn)
            load_activity        
          else
            pass
          end

        end

        #
        # Add an activity to the shopping cart
        #
        app.post '/p/activity/add-to-shopping-cart' do 

          activity_id = params[:activity_id]
          date = time = description = nil

          if params[:activity_date_id]
            if activity_date = ::Yito::Model::Booking::ActivityDate.get(params[:activity_date_id])
              date = activity_date.date_from
              time = activity_date.time_from
              description = activity_date.description
            end
          else
            date = DateTime.strptime(params[:date],'%Y-%m-%d')
            time = params[:turn]
          end
          quantity_rate_1 = params[:quantity_rate_1].to_i
          quantity_rate_2 = params[:quantity_rate_2].to_i
          quantity_rate_3 = params[:quantity_rate_3].to_i

          if activity = ::Yito::Model::Booking::Activity.get(activity_id)

            activity_name = activity.name
            activity_name << " (#{description})" unless description.nil?
            
            # Load or build the shopping cart
            @shopping_cart = nil

            ::Yito::Model::Order::ShoppingCart.transaction do 
              begin
                if session[:shopping_cart_id]
                  @shopping_cart = ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
                end
                if @shopping_cart.nil?
                  @shopping_cart = ::Yito::Model::Order::ShoppingCart.create(:creation_date => DateTime.now)
                end
                # Appends items
                if !quantity_rate_1.nil? and quantity_rate_1 > 0
                  @shopping_cart.add_item(date, 
                                          time, 
                                          activity.code, 
                                          activity_name,
                                          1,
                                          quantity_rate_1,
                                          activity.rates(date)[1][1],
                                          activity.price_1_description)
                end

                if !quantity_rate_2.nil? and quantity_rate_2 > 0
                  @shopping_cart.add_item(date, 
                                          time, 
                                          activity.code, 
                                          activity_name,
                                          2,
                                          quantity_rate_2,
                                          activity.rates(date)[2][1],
                                          activity.price_2_description) 
                end

                if !quantity_rate_3.nil? and quantity_rate_3 > 0
                  @shopping_cart.add_item(date, 
                                          time, 
                                          activity.code, 
                                          activity_name,
                                          3,
                                          quantity_rate_3,
                                          activity.rates(date)[3][1],
                                          activity.price_3_description)               
                end
              rescue DataMapper::SaveFailureError => error
                p "Error adding item(s) to shopping_cart. #{@shopping_cart.inspect} #{@shopping_cart.errors.inspect}"
                raise error
              end

            end

            if session.has_key?(:shopping_cart_id) 
              session[:shopping_cart_id] = @shopping_cart.id if session[:shopping_cart_id] != @shopping_cart.id
            else
              session[:shopping_cart_id] = @shopping_cart.id
            end

            session.delete(:activity_date_id)
            session.delete(:date)
            session.delete(:turn)

            redirect "/p/activities/shopping-cart"

          else
            redirect activity.alias
          end 

        end       
        
        #
        # Remove an item from the shopping cart
        #
        app.post '/p/activity/remove-to-shopping-cart' do  
        
          if shopping_cart_item = ::Yito::Model::Order::ShoppingCartItem.get(params[:id])
            shopping_cart_item.transaction do
              begin
                shopping_cart_item.shopping_cart.remove_item(shopping_cart_item.date,
                                                             shopping_cart_item.time,
                                                             shopping_cart_item.item_id)
              rescue DataMapper::SaveFailureError => error
                p "Error removing item from shopping cart. #{@shopping_cart.inspect} #{@shopping_cart.errors.inspect}"
                raise error
              end
            end              
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
              @shopping_cart.transaction do 
                begin
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
                rescue DataMapper::SaveFailureError => error
                  p "Error creating order from shopping cart. #{@order.inspect} #{@order.errors.inspect}"
                  raise error
                end               
              end

              if params[:pay_now].to_bool
                @order.notify_manager_pay_now
                @order.notify_request_to_customer_pay_now  
              else
                @order.notify_manager 
                @order.notify_request_to_customer
              end
              session.delete(:shopping_cart_id)
              session.delete(:activity_date_id)
              session.delete(:date)
              session.delete(:turn)               
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

          session.delete(:activity_date_id)
          session.delete(:date)
          session.delete(:turn)


          @activities = ::Yito::Model::Booking::Activity.all(active: true)
          load_page(:reservation_activities)

        end

        #
        # Show the programmed activities
        #
        app.get '/programmed-activities/?*' do

          date = Date.today

          @activities = ::Yito::Model::Order::Order.public_programmed_activities(date)
          load_page(:reservation_programmed_activities)

        end

        #
        # Show an activity
        #
        app.get '/p/activity/:id/?*' do
          
          @activity = ::Yito::Model::Booking::Activity.get(params[:id])
          load_activity

        end
      
        #
        # Select the date and/or turn
        #
        app.post '/p/activity/select-date/?*' do

          if @activity = ::Yito::Model::Booking::Activity.get(params[:activity_id]) and @activity.active
            
            @occupation = {total_occupation: 0, occupation_detail: {}}
            if params[:activity_date_id]
              @activity_date_id = params[:activity_date_id]
              if @activity_date = ::Yito::Model::Booking::ActivityDate.get(@activity_date_id)
                @occupation = @activity.occupation(@activity_date.date_from, @activity_date.time_from)
              end
              session[:activity_date_id] = @activity_date_id
            elsif params[:date] or params[:turn]
              @date = params[:date]
              @time = params[:turn]
              if @date and !@date.nil? and @time and !@time.nil?
                @occupation = @activity.occupation(@date, @time)
              end
              session[:date] = @date
              session[:turn] = @time
            end

            # Load or build the shopping cart
            @shopping_cart = nil
            
            if session[:shopping_cart_id]
              @shopping_cart = ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
            end

            unless @shopping_cart
              @shopping_cart = ::Yito::Model::Order::ShoppingCart.new(:creation_date => DateTime.now)
            end       
            
            if !@activity.alias.nil? and !@activity.alias.empty?
              redirect @activity.alias
            else
              redirect "/p/activity/#{@activity.id}"
            end
            
          else
            status 404
          end
              
        end


      end

    end
  end
end
