
require 'spec_helper'


describe Paho::MQTT::Client do
  let(:subject_class) { Paho::MQTT::Client }
  
  describe "destroy" do
    it "is not necessary to call" do
      subject
    end
    
    it "can be called several times to no additional effect" do
      subject.destroy
      subject.destroy
      subject.destroy
    end
    
    it "prevents any other network operations on the object" do
      subject.destroy
      expect { subject.start }.to raise_error Paho::MQTT::Client::DestroyedError
      expect { subject.close }.to raise_error Paho::MQTT::Client::DestroyedError
    end
  end
  
  describe "start" do
    it "initiates the connection to the server" do
      subject.start
    end
    
    it "can be called several times to reconnect" do
      subject.start
      subject.start
      subject.start
    end
  end
  
  describe "close" do
    it "closes the initiated connection" do
      subject.start
      subject.close
    end
    
    it "can be called several times to no additional effect" do
      subject.start
      subject.close
      subject.close
      subject.close
    end
    
    it "can be called before destroy" do
      subject.start
      subject.close
      subject.destroy
    end
    
    it "can be called before connecting to no effect" do
      subject.close
    end
  end
  
  it "uses Util.connection_info to parse info from its creation arguments" do
    args = ["parsable url", { foo: "bar" }]
    Paho::MQTT::Client::Util.should_receive(:connection_info).with(*args) {{
      username: "username",
      password: "password",
      host:     "host",
      port:     1234,
      ssl:      false
    }}
    subject = subject_class.new(*args)
    
    subject.options[:username].should eq "username"
    subject.options[:password].should eq "password"
    subject.options[:host]    .should eq "host"
    subject.options[:port]    .should eq 1234
    subject.options[:ssl]     .should eq false
  end
  
  describe "when not connected" do
    its(:connected?) { should eq false }
  end
  
  describe "when connected" do
    before { subject.start }
    after  { subject.close }
    
    its(:connected?) { should eq true }
    
    let(:topic) { "test/topic/#{SecureRandom.hex}" }
    let(:payload) { SecureRandom.hex }
    
    it "can subscribe to a topic" do
      subject.subscribe(topic).should eq subject
    end
    
    it "can unsubscribe from a topic" do
      subject.subscribe(topic)
      subject.unsubscribe(topic).should eq subject
    end
    
    it "can publish and get a message on a topic" do
      subject.subscribe(topic)
      
      subject.publish(topic, payload)
      
      subject.get.should eq ({
        topic:    topic,
        payload:  payload,
        retained: false,
        dup:      false,
      })
    end
    
    it "can publish a retained message then get it later" do
      subject.publish(topic, payload, retain: true, qos: 2)
      
      subject.subscribe(topic)
      
      subject.get.should eq ({
        topic:    topic,
        payload:  payload,
        retained: true,
        dup:      false,
      })
    end
  end
  
end
