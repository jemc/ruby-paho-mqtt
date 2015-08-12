
require 'ffi'


module Paho
  module MQTT
  
    # Bindings and wrappers for the native functions and structures exposed by
    # the Paho MQTT C library. This module is for internal use only so that
    # all dependencies on the implementation of the C library are abstracted.
    # @api private
    module FFI
      def self.load_into(mod)
        mod.instance_eval do
          extend ::FFI::Library
          
          libfile = "libpaho-mqtt3c.#{::FFI::Platform::LIBSUFFIX}"
          
          ffi_lib ::FFI::Library::LIBC
          ffi_lib \
            File.expand_path("../../../ext/paho/mqtt/#{libfile}", File.dirname(__FILE__))
          
          def self.opts
            {
              blocking: true  # only necessary on MRI to deal with the GIL.
            }
          end
          
          attach_function :free,   [:pointer], :void,    **opts
          attach_function :malloc, [:size_t],  :pointer, **opts
        end
      end
    end
  
  end
end
