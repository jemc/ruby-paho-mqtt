
require 'ffi'

module Paho
  module MQTT
    class Client
      
      # Bindings and wrappers for the native functions and structures exposed by
      # the Paho MQTT C library. This module is for internal use only so that
      # all dependencies on the implementation of the C library are abstracted.
      # @api private
      module FFI
        Paho::MQTT::FFI.load_into(self)
        
        Status = enum ::FFI::TypeDefs[:int], [
          :success,                0,
          :failure,               -1,
          :persistence_error,     -2,
          :disconnected,          -3,
          :max_messages_inflight, -4,
          :bad_utf8_string,       -5,
          :null_parameter,        -6,
          :topicname_truncated,   -7,
          :bad_structure,         -8,
          :bad_qos,               -9,
        ]
        
        StatusMessages = {
          success:               "No error. Indicates successful completion of an MQTT client operation",
          failure:               "A generic error code indicating the failure of an MQTT client operation",
          persistence_error:     "There was a problem with the data store for outbound and inbound messages",
          disconnected:          "The client is disconnected",
          max_messages_inflight: "The maximum number of messages allowed to be simultaneously in-flight has been reached",
          bad_utf8_string:       "An invalid UTF-8 string has been detected",
          null_parameter:        "A NULL parameter has been supplied when this is invalid",
          topicname_truncated:   "The topic has been truncated (the topic string includes embedded NULL characters). String functions will not access the full topic. Use the topic length value to access the full topic",
          bad_structure:         "A structure parameter does not have the correct eyecatcher and version number",
          bad_qos:               "A QoS value that falls outside of the acceptable range (0,1,2)",
        }
        
        PersistenceMode = enum ::FFI::TypeDefs[:int], [
          :default,  0,
          :none,     1,
          :user,     2,
        ]
        
        class Boolean
          extend ::FFI::DataConverter
          native_type ::FFI::TypeDefs[:int]
          def self.to_native val, ctx;   val ? 1 : 0; end
          def self.from_native val, ctx; val != 0;    end
        end
        
        module StructID
          def self.set(target, id)
            id.each_char.each_with_index { |chr, i| target[:struct_id][i] = chr.ord }
          end
        end
        
        class WillOptions < ::FFI::Struct
          layout :struct_id,      [:char, 4],
                 :struct_version, :int,
                 :topicName,      :pointer,
                 :message,        :pointer,
                 :retained,       Boolean,
                 :qos,            :int
          
          def initialize(*args) super
            if args.empty?
              StructID.set self, "MQTW"
              self[:struct_version] = 0
              self[:topicName]      = nil
              self[:message]        = nil
              self[:retained]       = false
              self[:qos]            = 0
            end
          end
        end
        
        class SSLOptions < ::FFI::Struct
          layout :struct_id,            [:char, 4],
                 :struct_version,       :int,
                 :trustStore,           :pointer,
                 :keyStore,             :pointer,
                 :privateKey,           :pointer,
                 :privateKeyPassword,   :pointer,
                 :enabledCipherSuites,  :pointer,
                 :enableServerCertAuth, Boolean
          
          def initialize(*args) super
            if args.empty?
              StructID.set self, "MQTS"
              self[:enableServerCertAuth] = true
              self[:trustStore]           = nil
              self[:keyStore]             = nil
              self[:privateKey]           = nil
              self[:privateKeyPassword]   = nil
              self[:enabledCipherSuites]  = nil
              self[:enableServerCertAuth] = false
            end
          end
        end
        
        class ConnectOptionsReturned < ::FFI::Struct
          layout :serverURI,      :pointer,
                 :mqtt_version,   :int,
                 :sessionPresent, Boolean
          
          def initialize(*args) super
            if args.empty?
              self[:serverURI]      = nil
              self[:mqtt_version]   = 0
              self[:sessionPresent] = false
            end
          end
        end
        
        class ConnectOptions < ::FFI::Struct
          layout :struct_id,         [:char, 4],
                 :struct_version,    :int,
                 :keepAliveInterval, :int,
                 :cleansession,      Boolean,
                 :reliable,          Boolean,
                 :will,              :pointer, # WillOptions.ptr,
                 :username,          :pointer,
                 :password,          :pointer,
                 :connectTimeout,    :int,
                 :retryInterval,     :int,
                 :ssl,               :pointer, # SSLOptions.ptr,
                 :serverURIcount,    :int,
                 :serverURIs,        :pointer,
                 :mqtt_version,      :int,
                 :returned,          ConnectOptionsReturned
          
          def initialize(*args) super
            if args.empty?
              StructID.set self, "MQTC"
              self[:struct_version]    = 4
              self[:keepAliveInterval] = 60
              self[:cleansession]      = true
              self[:reliable]          = true
              self[:will]              = nil
              self[:username]          = nil
              self[:password]          = nil
              self[:connectTimeout]    = 30
              self[:retryInterval]     = 20
              self[:ssl]               = nil
              self[:serverURIcount]    = 0
              self[:serverURIs]        = nil
              self[:mqtt_version]      = 0
            end
          end
        end
        
        class Message < ::FFI::Struct
          layout :struct_id,      [:char, 4],
                 :struct_version, :int,
                 :payloadlen,     :int,
                 :payload,        :pointer,
                 :qos,            :int,
                 :retained,       Boolean,
                 :dup,            Boolean,
                 :msgid,          :int
          
          def initialize(*args) super
            if args.empty?
              StructID.set self, "MQTM"
              self[:struct_version] = 0
              self[:payloadlen]     = 0
              self[:payload]        = nil
              self[:qos]            = 0
              self[:retained]       = false
              self[:dup]            = false
              self[:msgid]          = 0
            end
          end
        end
        
        client      = :pointer
        client_addr = :pointer
        
        attach_function :MQTTClient_create,                   [client_addr, :string, :string, PersistenceMode, :pointer], Status,  **opts
        attach_function :MQTTClient_connect,                  [client, ConnectOptions.ptr],                               Status,  **opts
        attach_function :MQTTClient_disconnect,               [client, :int],                                             Status,  **opts
        attach_function :MQTTClient_isConnected,              [client],                                                   Boolean, **opts
        attach_function :MQTTClient_subscribe,                [client, :string, :int],                                    Status,  **opts
        attach_function :MQTTClient_unsubscribe,              [client, :string],                                          Status,  **opts
        attach_function :MQTTClient_publish,                  [client, :string, :int, :pointer, :int, Boolean, :pointer], Status,  **opts
        attach_function :MQTTClient_waitForCompletion,        [client, :int, :ulong],                                     Status,  **opts
        attach_function :MQTTClient_getPendingDeliveryTokens, [client, :pointer],                                         Status,  **opts
        attach_function :MQTTClient_yield,                    [],                                                         :void,   **opts
        attach_function :MQTTClient_receive,                  [client, :pointer, :pointer, :pointer, :ulong],             Status,  **opts
        attach_function :MQTTClient_freeMessage,              [:pointer],                                                 :void,   **opts
        attach_function :MQTTClient_free,                     [:pointer],                                                 :void,   **opts
        attach_function :MQTTClient_destroy,                  [client_addr],                                              :void,   **opts
      end
      
    end
  end
end
