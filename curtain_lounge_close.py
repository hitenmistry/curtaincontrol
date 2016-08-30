#!/usr/bin/python 
import RPi.GPIO as GPIO 
import time 
import cpi6x 
GPIO.setmode(GPIO.BOARD) 
#start program 
board1=cpi6x.add1 
cpi6x.setasoutput(board1) 
for y in range (0,5): 
	for x in range (0,2): 
		cpi6x.setbit(board1, cpi6x.ONrelay0) 
		time.sleep(0.4)
		cpi6x.clrbit(board1, cpi6x.OFFrelay0) 
	time.sleep(5)
import sys 
sys.exit()
GPIO.cleanup() 
