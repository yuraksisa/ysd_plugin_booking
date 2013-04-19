require 'spec_helper'
require 'rack/test'
require 'json'
require 'ysd_md_booking'
require 'ysd_md_payment'

describe Sinatra::YSD::BookingRESTApi do
  include Rack::Test::Methods

  def app  
    TestingSinatraApp.register Sinatra::YSD::BookingRESTApi
    TestingSinatraApp.class_eval do
      get '/charge' do
        'Charge done'
      end
    end
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

  context "booking with charge" do

    before :each do 
      
      new_booking = double('booking')

      BookingDataSystem::Booking.should_receive(:new).with(
      	booking['booking'].keep_if {|key, value| key != 'non_existing_prop'}).
        and_return(new_booking)

      new_booking.should_receive(:id).and_return(1)
      new_booking.should_receive(:save)
      new_booking.should_receive(:charges).twice.and_return([
        Payments::Charge.new({:amount => 20, :currency => 'EUR',
          :payment_method_id => 'cecabank'})])
    
    end
    
    subject do
      post('/confirm_booking', booking.to_json, 
      	'CONTENT_TYPE' => 'application/json')
      last_response
    end
    
    its(:status) { should == 200 }  
    its(:header) { should have_key 'Content-Type' } 
    it { subject.header['Content-Type'].should match(/text\/html/)  } 
    its(:body)   { should == 'Charge done' }

  end

  context "booking without charge" do
  
    before :each do

      new_booking = double('booking')

      BookingDataSystem::Booking.should_receive(:new).with(
        booking['booking'].keep_if {|key, value| key != 'non_existing_prop'}).
        and_return(new_booking)
      
      new_booking.should_receive(:save)
      new_booking.should_receive(:charges).and_return([])
      new_booking.should_receive(:to_json).and_return("{id:999}")

    end

    subject do
      post('/confirm_booking', booking.to_json, 
        'CONTENT_TYPE' => 'application/json')
      last_response
    end
    
    its(:status) { should == 200 } 
    its(:header) { should have_key 'Content-Type' }
    it { subject.header['Content-Type'].should match(/application\/json/) }
    its(:body) { should == '{id:999}'}

  end


end