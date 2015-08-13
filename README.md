# paho-mqtt

A Ruby [MQTT](http://mqtt.org/) client library based on [FFI](https://github.com/ffi/ffi/wiki) bindings for the [Paho MQTT C library](https://github.com/eclipse/paho.mqtt.c).

## WARNING

Don't use this library. The code is not supported and only exists here for archival purposes. It was never even released, because the Paho MQTT library has backend [race conditions](https://bugs.eclipse.org/bugs/show_bug.cgi?id=474748) that preclude using multiple synchronous clients from separate threads.

Use [the `mosq` gem](https://github.com/jemc/ruby-mosq) instead, which wraps [libmosquitto](http://mosquitto.org/man/libmosquitto-3.html).
