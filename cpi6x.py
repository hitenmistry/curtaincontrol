#1/usr/bin/env python
import time
import smbus

#********************************************
# Custard Pi 6 resources v2.0 9th Sept 2013

#I2C addresses
#use switch S1 on Custard Pi 6 to set the address

add0= 0x20
add1= 0x21
add2= 0x22
add3= 0x23
add4= 0x24
add5= 0x25
add6= 0x26
add7= 0x27

bus=smbus.SMBus(1)

#set IODIR register
iodir= 0x00
#set default to all off
allout= 0x00
#set GPIO register
gpio= 0x09
#set output latch
olat=0x0A

#set relay ON
ONrelay0= 0x01
ONrelay1= 0x02
ONrelay2= 0x04
ONrelay3= 0x08
ONrelay4= 0x10
ONrelay5= 0x20
ONrelay6= 0x40
ONrelay7= 0x80

#set relay OFF
OFFrelay0= 0xFE
OFFrelay1= 0xFD
OFFrelay2= 0xFB
OFFrelay3= 0xF7
OFFrelay4= 0xEF
OFFrelay5= 0xDF
OFFrelay6= 0xBF
OFFrelay7= 0x7F

def setbit(address, byte):
    #sets selected port pin
    outstatus = bus.read_byte_data(address, olat) | byte
    bus.write_byte_data(address, gpio, outstatus)

def clrbit(address, byte):
    #clears selected port pin
    outstatus = bus.read_byte_data(address, olat) & byte
    bus.write_byte_data (address, gpio, outstatus)
    
def setasoutput(address):            
    #set all 8 bits as outputs
    bus.write_byte_data(address, iodir, allout)

def alloff(address):
    #clear all relays
    bus.write_byte_data (address, gpio, 0x00)

#******************************************
