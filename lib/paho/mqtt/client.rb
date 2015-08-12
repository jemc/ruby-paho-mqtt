
require_relative "client/util"
require_relative "client/ffi"
require_relative "client/ffi/error"

require "securerandom"

module Paho
  module MQTT
    class Client
      
      # Raised when an operation is performed on an already-destroyed {Client}.
      class DestroyedError < RuntimeError; end
      
      # Create a new {Client} instance with the given properties.
      def initialize(*args)
        @options = Util.connection_info(*args)
        
        uri = if @options[:username] && @options[:password]
          "tcp://#{@options[:username]}:#{@options[:password]}@"\
                    "#{@options[:host]}:#{@options[:port]}"
        else
          "tcp://#{@options[:host]}:#{@options[:port]}"
        end
        
        client_id = @options[:client_id] = \
          ("paho" + (SecureRandom.random_number*1e36).to_i.to_s(36))[0...23] \
            unless @options[:client_id]
        
        client_ptr = Util.mem_ptr(:pointer)
        self.class.cycle_sync do
          Util.error_check "creating the client",
            FFI.MQTTClient_create(client_ptr, uri, client_id, :none, nil)
          self.class.start_yield_thread!
        end
        @ptr = client_ptr.read_pointer
        
        ptr_ptr = Util.mem_ptr(:pointer)
        ptr_ptr.write_pointer(ptr)
        @finalizer = self.class.create_finalizer_for(ptr_ptr)
        ObjectSpace.define_finalizer(self, @finalizer)
      end
      
      # @api private
      def self.create_finalizer_for(ptr_ptr)
        Proc.new do
          FFI.MQTTClient_disconnect(ptr_ptr.read_pointer, 0)
          FFI.MQTTClient_destroy(ptr_ptr)
          ptr_ptr.free
        end
      end
      
      attr_reader :options
      
      def ptr
        raise DestroyedError unless @ptr
        @ptr
      end
      private :ptr
      
      # Initiate the connection with the server.
      # It is necessary to call this before any other communication.
      def start(timeout: 30.0)
        c_opts = FFI::ConnectOptions.new
        c_opts[:connectTimeout] = Integer(timeout)
        
        self.class.cycle_sync do
          Util.error_check "connecting to #{@options[:host]}",
            FFI.MQTTClient_connect(ptr, c_opts)
        end
        
        self
      end
      
      # Gracefully close the connection with the server. This will
      # be done automatically on garbage collection if not called explicitly.
      def close(timeout: 5.0)
        timeout_ms = Integer(timeout*1e3)
        begin
          Util.error_check "closing the connection to #{@options[:host]}",
            FFI.MQTTClient_disconnect(ptr, timeout_ms)
        rescue Client::FFI::Error::Disconnected
        end
        
        self
      end
      
      # Free the native resources associated with this object. This will
      # be done automatically on garbage collection if not called explicitly.
      def destroy
        if @finalizer
          @finalizer.call
          ObjectSpace.undefine_finalizer(self)
        end
        @ptr = @finalizer = nil
        
        self
      end
      
      def connected?
        FFI.MQTTClient_isConnected(ptr)
      end
      
      def subscribe(topic, qos: 0)
        self.class.cycle_sync do
          Util.error_check "subscribing to a topic", \
            FFI.MQTTClient_subscribe(ptr, topic, qos)
        end
        
        self
      end
      
      def unsubscribe(topic)
        self.class.cycle_sync do
          Util.error_check "unsubscribing from a topic", \
            FFI.MQTTClient_unsubscribe(ptr, topic)
        end
        
        self
      end
      
      def get(timeout: 5.0)
        timeout_ms = Integer(timeout * 1e3)
        
        msg_ptr = Util.mem_ptr(:pointer)
        topic_ptr = Util.mem_ptr(:pointer)
        topic_size_ptr = Util.mem_ptr(:int)
        
        begin
          self.class.cycle_sync do
            Util.error_check "receiving the next message", \
              FFI.MQTTClient_receive(ptr, topic_ptr, topic_size_ptr,
                                     msg_ptr, timeout_ms)
          end
        rescue Client::FFI::Error::TopicnameTruncated
        end
        
        msg = FFI::Message.new(msg_ptr.read_pointer)
        res = {
          topic:    topic_ptr.read_pointer.read_bytes(topic_size_ptr.read_int),
          payload:  msg[:payload].read_bytes(msg[:payloadlen]),
          retained: msg[:retained],
          dup:      msg[:dup],
        }
        
        FFI.MQTTClient_freeMessage(msg_ptr)
        
        res
      end
      
      def publish(topic, payload, retain: false, qos: 0,
                                  async: false, timeout: 30.0)
        payload_ptr = Util.strdup_ptr(payload)
        token_ptr   = Util.mem_ptr(:int) unless async
        
        Util.error_check "publishing a message", \
          FFI.MQTTClient_publish(ptr, topic, payload.bytesize, payload_ptr,
                                 qos, retain, token_ptr)
        
        unless async
          token = token_ptr.read_int
          timeout_ms = Integer(timeout * 1e3)
          Util.error_check "waiting for publish confirmation", \
            FFI.MQTTClient_waitForCompletion(@ptr, token, timeout_ms)
        end
        
        self
      end
      
      # TODO: Remove when paho-mqtt-c race conditions are fixed.
      # See https://bugs.eclipse.org/bugs/show_bug.cgi?id=474748
      # Specifically, functions that receive server responses are not safe to
      # be called concurrently with the MQTTClient_yield function, class-wide.
      # @api private
      @cycle_mutex = Mutex.new
      
      # @api private
      def self.cycle_sync(&block)
        @cycle_mutex.synchronize(&block)
      end
      
      # @api private
      def self.start_yield_thread!
        @yield_thread ||= Thread.new do
          while true
            cycle_sync { FFI.MQTTClient_yield }
            
            # Remove this sleep when checking for cycle_sync-related races.
            # Removing the sleep will cause processing to become more
            # CPU-intensive and inefficient, but it will NOT hang the
            # application or tests unless there is a race condition with
            # a function that needs to be wrapped with cycle_sync.
            sleep 0.5
          end
        end
      end
      
    end
  end
end