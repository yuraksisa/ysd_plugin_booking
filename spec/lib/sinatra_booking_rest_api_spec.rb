require 'spec_helper'
require 'rack/test'
require 'json'

describe Sinatra::YSD::BookingRESTApi do
  include Rack::Test::Methods

  def app  
  	TestingSinatraApp.register Sinatra::YSD::BookingRESTApi
    TestingSinatraApp
  end
  
  let(:booking) { {'booking' => {
      	'date_from' => Time.utc(2013, 3, 1).to_s,
      	'date_to' => Time.utc(2013,3, 3).to_s ,
      	'item_id' => 'A',
      	'item_cost' => 30,
      	'extras_cost' => 20,
      	'total_cost' => 50,
      	'booking_amount' => 20,
      	'payment_method_id' => 'cecabank',
      	'quantity' => 1,
      	'date_to_price_calculation' => Time.utc(2013, 3, 3).to_s,
      	'days' => 2,
      	'customer_name' => 'Mr. John',
      	'customer_surname' => 'Smith',
      	'customer_email' => 'john.smith@test.com',
      	'customer_phone' => '935551010',
      	'customer_mobile_phone' => '666101010',
      	'comments' => 'Nothing',
       	'booking_extras' => [{'extra_id' => 'cuna',
      		                 'extra_cost' => 20,
      		                 'extra_unit_cost' => 10,
      		                 'quantity' => 1}],
        'non_existing_prop' => 'value'
        }} }

  context "online payment method" do

    before do 
      booking_model = double('booking')
      BookingDataSystem::Booking.should_receive(:new).with(
      	booking['booking'].keep_if {|key, value| key != 'non_existing_prop'}).
        and_return(booking_model)
      booking_model.should_receive(:save)
    end

    it "creates a new booking" do

      post('/confirm_booking', booking.to_json, 
      	'CONTENT_TYPE' => 'application/json')

      last_response.should be_ok
      last_response.headers['Content-Type'].should match /text\/html/ 

    end

  end

  #context "offline payment method" do
  #
  #end

  #context "no payment" do
  #
  #end

end