# Stonework

Pebble emulator for running native Pebble watchfaces on Apple Watch.

## Features

* ARM Cortex-M4 application-mode CPU emulator
    * 16 and 32-bit thumb instruction set
    * application-mode only
    * doesn't implement exceptions
    * custom built, API loosely modelled after [unicorn](https://github.com/unicorn-engine/unicorn)
* Subset of Pebble API for running watchfaces
    * Some bitmap and font code adapted from [neographics](https://github.com/pebble-dev/neographics)
    * Work in progress, can run some watchfaces already
* Built-in [rebble store](https://apps.rebble.io) browser to install watchfaces
* Install watchfaces from Files or other sources
* Preview the running watchface on iOS before sending it to the watch

### To Do

* Implement more of the Pebble API to run more watchfaces
    * Unimplemented drawing functions
    * Animation
    * Accelerometer
    * Battery
    * Communication
    * and many more
* Configuration for configurable watchfaces
* rocky.js watchfaces?

## Requirements

* iOS 12
* WatchOS 5
