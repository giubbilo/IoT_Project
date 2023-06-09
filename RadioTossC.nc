#include "Timer.h"
#include "RadioToss.h"
 
/**
 *
 * @author Gabriele Karra, Davide Giannubilo
 * @date   May 9 2023
 */

module RadioTossC @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;
  uint16_t indexConnected[8] = {0, 0, 0, 0, 0, 0, 0, 0};
  uint8_t i=0;

  bool locked;
  
  event void Boot.booted() {
    dbg("boot","Application booted.\n");
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    	if(TOS_NODE_ID == 1) dbg("radio","Radio on on PAN coordinator !\n");
      	else dbg("radio","Radio on on node %d!\n", TOS_NODE_ID-1);
      	call MilliTimer.startPeriodic(250);
    }
    else {
      dbgerror("radio", "Radio failed to start, retrying...\n");
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    dbg("boot", "Radio stopped!\n");
  }
  
  event void MilliTimer.fired() {
    if(TOS_NODE_ID == 1) return;
    if (locked) return;
    else {
      radio_toss_msg_t* rcm = (radio_toss_msg_t*)call Packet.getPayload(&packet, sizeof(radio_toss_msg_t));
      if (rcm == NULL) {
		return;
      }
      
      if (call AMSend.send(1, &packet, sizeof(radio_toss_msg_t)) == SUCCESS) {
      	rcm->sender = TOS_NODE_ID;
      	rcm->type = 0; // ACK TYPE
		dbg("radio_send", "Try to connect...send ACK to PAN coordinator\n");	
		//dbg_clear("radio_send", " at time %s \n", sim_time_string());
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    if (len != sizeof(radio_toss_msg_t)) return;
    else {
    	radio_toss_msg_t* rcm = (radio_toss_msg_t*)payload;
    	if(TOS_NODE_ID == 1 && rcm->type==0) {
    		dbg("radio_rec", "Received ACK from %d\n", rcm->sender-1);
    		indexConnected[rcm->sender-2] = rcm->sender-1; 
    		
    		for (i = 0; i < 8; ++i) {
  				printf("%u ", indexConnected[i]);
			}
			printf("\n");
    	}
    	return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
  	if (&packet == bufPtr && error == SUCCESS) {
      	dbg("radio_send", "Packet sent...\n");
      	locked = TRUE;
  	}
  	/*if (error != SUCCESS) {
  		dbg("radio_send", "Packet LOST, send again to PAN...\n");
  		call AMSend.send(1, &packet, sizeof(radio_toss_msg_t));
  	}*/
  }

}




