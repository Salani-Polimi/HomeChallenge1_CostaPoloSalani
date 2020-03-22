// $Id: RadioCountToLedsC.nc,v 1.7 2010-06-29 22:07:17 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
 
#include "Timer.h"
#include "Hw1.h"
#include <stdio.h>
#include <stdint.h>
#include <string.h>
 
/**
 * Implementation of the RadioCountToLeds application. RadioCountToLeds 
 * maintains a 4Hz counter, broadcasting its value in an AM packet 
 * every time it gets updated. A RadioCountToLeds node that hears a counter 
 * displays the bottom three bits on its LEDs. This application is a useful 
 * test to show that basic AM communication and timers work.
 *
 * @author Philip Levis
 * @date   June 6 2005
 */

module Hw1C @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive; //interface receiving mx
    interface AMSend;  //int send packets
    interface Timer<TMilli> as Timer0;
    interface Timer<TMilli> as Timer1;
    interface Timer<TMilli> as Timer2;
    interface SplitControl as AMControl; //manage packet
    interface Packet;
  }
}
implementation {
 
 

  message_t packet; //packet variable
  //booleans used to control the leads
  bool mote1=TRUE;
  bool mote2=TRUE;
  bool mote3=TRUE;
  bool locked;
  uint16_t counter = 0; // counter max 16 bytes variable
  
  event void Boot.booted() {
    call AMControl.start(); //starts the radio
  }	
  //when is started, this event is triggered
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) { //if radio starts badly
      switch(TOS_NODE_ID){
       case 1:
        call Timer0.startPeriodic(1000);
       break;
       case 2:
        call Timer1.startPeriodic(333);
       break;
       case 3:
        call Timer2.startPeriodic(200);
       break;
     }
    }
    else {
      call AMControl.start();
    }
  }
  

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  //everytime the timer is fired we send a message
  event void Timer0.fired() {
    dbg("Hw1C", "Hw1C: timer fired, counter is %hu.\n", counter);
    if (locked) {
      return;
    }
    else {
     //creating the message size of payload
     //variable della struct
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
      if (rcm == NULL) {
	return; //if not corrected
      }
		//we assign the counter one if the termini della struct ovvero il counter
      rcm->counter = counter;
      rcm->sender_id= TOS_NODE_ID;
      
      //we are sendig the message in broadcast to everyone
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
	dbg("Hw1C", "Hw1C: packet sent.\n", counter);	
	locked = TRUE;
      }
    }
    
  }
  event void Timer1.fired() {
    dbg("Hw1C", "Hw1C: timer fired, counter is %hu.\n", counter);
    if (locked) {
      return;
    }
    else {
     //creating the message size of payload
     //variable della struct
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
      if (rcm == NULL) {
	return; //if not corrected
      }
		//we assign the counter one if the termini della struct ovvero il counter
      rcm->counter = counter;
      rcm->sender_id=TOS_NODE_ID;
      
      //we are sendig the message in broadcast to everyone
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
	dbg("Hw1C", "Hw1C: packet sent.\n", counter);	
	locked = TRUE;
      }
    }
    
  }
  event void Timer2.fired() { 
    dbg("Hw1C", "Hw1C: timer fired, counter is %hu.\n", counter);
    if (locked) {
      return;
    }
    else {
     //creating the message size of payload
     //variable della struct
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
      if (rcm == NULL) {
	return; //if not corrected
      }
		//we assign the counter one if the termini della struct ovvero il counter
      rcm->counter = counter;
      rcm->sender_id=TOS_NODE_ID;
      
      //we are sendig the message in broadcast to everyone
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
	dbg("Hw1C", "Hw1C: packet sent.\n", counter);	
	  locked = TRUE;
      }
    }
    
  }
  
	//event message arrives
  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    dbg("Hw1C", "Received packet of length %hhu.\n", len);
    //check size message equal size what we have received
    if (len != sizeof(radio_count_msg_t)) {return bufPtr;}
    else {
      //we take the payload of the message and the assign to rcm
      radio_count_msg_t* rcm = (radio_count_msg_t*)payload; 
      
      counter++;
      //avoid changing the internal counter  
      if(counter==11){
       counter=1;
      }
      
      printf("\n Counter=%d",counter);  
      
      if((rcm->counter)==10){ 
       
        call Leds.led0Off();
        call Leds.led1Off();
        call Leds.led2Off(); 
        
        printf("\n Node: %d 10 Turn the leds off \n",rcm->sender_id);
   
      }
      else{
        switch(rcm->sender_id){
        case 1: 
        if (mote1==TRUE) {
			call Leds.led0On();
			mote1=FALSE;
      	}
      	else{
			call Leds.led0Off();
			mote1=TRUE;
       }     
        //dbg("Hw1C", "Hw1C dentro led rosso", counter);	
     
       break;
       case 2:
        
         if (mote2==TRUE) {
			call Leds.led1On();
		 	mote2=FALSE;
      	 }
      	 else {
			call Leds.led1Off();
			mote2=TRUE;
      	 }
        //dbg("Hw1C", "Hw1C dentro led verde", counter);
 
       break;
       
       case 3:
       
        if (mote3==TRUE) {
			call Leds.led2On();
			mote3=FALSE;
      	}
      	else {
			call Leds.led2Off();
			mote3=TRUE;
      	}
        
        //dbg("Hw1C", "Hw1C dentro led blu", counter);
    
       break;
       }
      }
      return bufPtr;
    }
  }
  
 
   


  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }
  
  

}




