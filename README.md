# paho-mqtt

[![Build Status](https://circleci.com/gh/jemc/ruby-paho-mqtt/tree/master.svg?style=svg)](https://circleci.com/gh/jemc/ruby-paho-mqtt/tree/master) 
[![Gem Version](https://badge.fury.io/rb/paho.png)](http://badge.fury.io/rb/paho) 
[![Join the chat at https://gitter.im/jemc/ruby-paho-mqtt](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jemc/ruby-paho-mqtt?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A Ruby [MQTT](http://mqtt.org/) client library based on [FFI](https://github.com/ffi/ffi/wiki) bindings for the [Paho MQTT C library](https://github.com/eclipse/paho.mqtt.c).

##### `$ gem install paho-mqtt`

## Design Goals

- Provide a minimal API for creating useful MQTT applications in Ruby.
- Use a minimal resource and execution path footprint.
- No interruptions or Ruby callbacks invoked across thread boundaries.
- Favor directness over convenience.
- Use an existing protocol library (paho-mqtt-c) instead of reinventing one.
- Avoid making precluding assumptions about what a user needs.
