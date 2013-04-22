require 'spec_helper'
require 'rack/test'
require 'ysd_md_booking' unless defined?BookingDataSystem::Booking
require 'ysd_md_payment' unless defined?Payments::Charge
require 'ysd_core_themes' unless defined?Themes::ThemeManager

describe Sinatra::YSD::Booking do 
  include Rack::Test::Methods
  include ThemeMock

 def app  
   TestingSinatraApp.register Sinatra::YSD::Booking
   TestingSinatraApp.class_eval do
     get '/charge' do
       'Charge done'
     end
   end
   TestingSinatraApp
 end

 let(:booking) {  {:date_from => Time.new(2013, 05, 10),
   	               :time_from => '10:00',
   	               :date_to => Time.new(2013, 05, 11),
   	               :time_to => '10:00',
   	               :item_id => 'A',
   	               :item_description => 'Clase A',
   	               :item_cost => 40,
   	               :extras_cost => 10,
   	               :total_cost => 50,
   	               :booking_amount => 10,
   	               :payment_method_id => :pi4b,
   	               :quantity => 1,
   	               :date_to_price_calculation => Time.new(2013, 05, 11),
   	               :days => 1,
   	               :customer_name => 'Jose Luis',
   	               :customer_surname => 'Perez',
   	               :customer_email => 'jose.luis.perez@gmail.com',
   	               :customer_phone => '935551010',
   	               :customer_mobile_phone => '666101010',
   	               :comments => 'no comments',
   	               :booking_extras => [{:extra_id => 'B' ,
   	                                   :extra_description => 'EXTRA B',
   	                                   :extra_unit_cost => 10, 
   	                                   :extra_cost => 10,
   	                                   :quantity => 1}]
   	              }
 }

 #
 # Reserva form 
 #
 describe "/reserva" do
   
   before :each do
     init_theme
   end

   subject do
     get '/reserva'
     last_response
   end
    
   it { should be_ok }
   its(:header) { should have_key 'Content-Type' }
   it { subject.header['Content-Type'].should match(/text\/html/) }
   its(:body) { should match /id="content-reserva"/ }

 end

 #
 # Reserva payment gateway return (ok)
 #
 describe "/reserva/payment-gateway-return/ok" do
   
   before :each do
     init_theme
   end

   context "booking_id in session and in database" do
     before :each do
       BookingDataSystem::Booking.should_receive(:get).with(1).and_return(BookingDataSystem::Booking.new(booking))
     end
     subject do
       get '/reserva/payment-gateway-return/ok', {}, {'rack.session' => {'booking_id' => 1}}
       last_response
     end
     it { should be_ok}
     its(:body) { should match /<h2>Reserva recibida<\/h2>/ }
   end

   context "no booking_id in session" do
   	 subject do
   	   get 'reserva/payment-gateway-return/ok'
   	   last_response
   	 end
   	 its(:status) { should == 404 }
   end

 end
 
 #
 # Reserva payment gateway return (error)
 #
 describe "/reserva/payment-gateway-return/nok" do

   before :each do
     init_theme
   end

   context "booking_id in session and in database" do
     before :each do
       BookingDataSystem::Booking.should_receive(:get).with(1).and_return(BookingDataSystem::Booking.new(booking))
     end
     subject do
       get '/reserva/payment-gateway-return/nok', {}, {'rack.session' => {'booking_id' => 1} }
       last_response
     end
     it { should be_ok }
     its(:body) { should match /<h2>Reserva<\/h2>/ }
   end

   context "no booking_id in session" do
   	 subject do
   	   get 'reserva/payment-gateway-return/nok'
   	   last_response
   	 end
   	 its(:status) { should == 404 }   
   end

 end
 
 #
 # Reserva create a charge deposit
 #
 describe "/reserva/charge-deposit" do

   context "booking_id in session and in database" do
     before :each do
       built_booking = BookingDataSystem::Booking.new(booking)
       BookingDataSystem::Booking.should_receive(:get).with(1).and_return(built_booking)
       built_booking.should_receive(:create_deposit_charge!).
         and_return(Payments::Charge.new(:amount => 10, 
         :payment_method_id => :pi4b))
     end
     subject do
       get '/reserva/charge-deposit', {}, {'rack.session' => {'booking_id' => 1} }
       last_response
     end
     it {should be_ok}
     it { subject.header['Content-Type'].should match(/text\/html/)  } 
     its(:body)   { should == 'Charge done' }
   end

   context "no booking_id in session" do
   	 subject do
   	   get 'reserva/charge-deposit'
   	   last_response
   	 end
   	 its(:status) { should == 404 }   
   end

 end



end