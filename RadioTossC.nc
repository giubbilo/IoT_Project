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
    if (locked) return;
    else {
      radio_toss_msg_t* rcm = (radio_toss_msg_t*)call Packet.getPayload(&packet, sizeof(radio_toss_msg_t));
      if (rcm == NULL) {
		return;
      }
      if (TOS_NODE_ID != 1 && indexAckReceived[TOS_NODE_ID-2] == 0) {
      	rcm->sender = TOS_NODE_ID;
      	rcm->type = 0; // ACK TYPE
      	rcm->dest = 1;
      	call AMSend.send(rcm->dest, &packet, sizeof(radio_toss_msg_t));
		dbg("radio_send", "Try to connect...send ACK to PAN coordinator\n");	
		//dbg_clear("radio_send", " at time %s \n", sim_time_string());
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    if (len != sizeof(radio_toss_msg_t)) return;
    else {
    	radio_toss_msg_t* rcm = (radio_toss_msg_t*)payload;
    	// dbg("radio_rec", "rcm->sender: %d, rcm->dest: %d, rcm->type: %d\n", rcm->sender, rcm->dest, rcm->type);
    	if (TOS_NODE_ID != 1) {
    		if(rcm->type == 1 && indexConnAckReceived[rcm->dest-2] == 0){
				dbg("radio_rec", "Received CONNACK from PAN coordinator, node: %d connected !!!\n", TOS_NODE_ID-1);
				indexConnAckReceived[TOS_NODE_ID-2] = TOS_NODE_ID-1;
				// for (i = 0; i < 8; ++i) { printf("%u ", indexConnAckReceived[i]); } printf("\n"); // stampa connack ricevuti correttamente
			}
			if(rcm->type == 3 && indexSubAckReceived[rcm->dest-2] == 0){
				dbg("radio_rec", "Received SUBBACK from PAN coordinator, node: %d subbed !!!\n", TOS_NODE_ID-1);
				indexSubAckReceived[TOS_NODE_ID-2] = TOS_NODE_ID-1;
				// for (i = 0; i < 8; ++i) { printf("%u ", indexSubAckReceived[i]); } printf("\n"); // stampa connack ricevuti correttamente
			}
    	}
    	if(TOS_NODE_ID == 1) {
    		if(rcm->type == 2){
    			dbg("radio_rec", "Received SUB from node: %d\n", rcm->sender-1);
    			indexSubReceived[rcm->sender-2] = rcm->sender-1;
    			dbg("radio_send", "Send SUBBACK to node: %d\n", rcm->sender-1);	
    			rcm->type = 3; // CONNACK TYPE
    			rcm->dest = rcm->sender;
    			rcm->sender = 1;
    			call AMSend.send(rcm->dest, bufPtr, sizeof(radio_toss_msg_t));
    			// for (i = 0; i < 8; ++i) { printf("%u ", indexSubReceived[i]); } printf("\n"); // stampa connack ricevuti correttamente
    	 	}
    		if(rcm->type == 0){
    			dbg("radio_rec", "Received ACK from node: %d\n", rcm->sender-1);
   		 		indexAckReceived[rcm->sender-2] = rcm->sender-1;
    			dbg("radio_send", "Send CONNACK to node: %d\n", rcm->sender-1);	
    			rcm->type = 1; // CONNACK TYPE
    			rcm->dest = rcm->sender;
    			rcm->sender = 1;
    			call AMSend.send(rcm->dest, bufPtr, sizeof(radio_toss_msg_t));
    	 		// for (i = 0; i < 8; ++i) { printf("%u ", indexAckReceived[i]); } printf("\n"); // stampa ack ricevuti correttamente
    	 	}	
    	}
    	return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
  radio_toss_msg_t* rcm = (radio_toss_msg_t*)call Packet.getPayload(&packet, sizeof(radio_toss_msg_t));
  	if (&packet == bufPtr && error == SUCCESS) {
      	//dbg("radio_send", "Packet sent...\n");
      	locked = TRUE;	
  	}
  	if (indexAckReceived[TOS_NODE_ID-2] == 0 && TOS_NODE_ID != 1) {
		dbg("radio_send", "PACKET LOST...send AGAIN ACK to PAN coordinator\n");	
		call AMSend.send(1, &packet, sizeof(radio_toss_msg_t));
		//dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }
  	if(TOS_NODE_ID != 1 && indexConnAckReceived[TOS_NODE_ID-2] == 0 && indexAckReceived[TOS_NODE_ID-2] != 0) { // SE NON SONO IL PAN E NON HO ANCORA RICEVUTO IL CONNACK TRIGGERO IL PAN
   		rcm->type = 0;
   		rcm->sender = TOS_NODE_ID;
   		rcm->dest = 1;
   		call AMSend.send(rcm->dest, &packet, sizeof(radio_toss_msg_t));
    }	
    if (indexSubReceived[TOS_NODE_ID-2] == 0 && TOS_NODE_ID != 1 && indexConnAckReceived[TOS_NODE_ID-2] != 0 && indexAckReceived[TOS_NODE_ID-2] != 0) {
		rcm->topic = TOS_NODE_ID%3;
      	rcm->type = 2; // SUB TYPE
    	rcm->dest = 1;
   		rcm->sender = TOS_NODE_ID;
		if(rcm->topic == 0) dbg("radio_send", "Sono connesso posso fare una SUBSCRIBE, topic: TEMPERATURE\n");
		else if(rcm->topic == 1) dbg("radio_send", "Sono connesso posso fare una SUBSCRIBE, topic: HUMIDITY\n");
		else if(rcm->topic == 2) dbg("radio_send", "Sono connesso posso fare una SUBSCRIBE, topic: LUMINOSITY\n");
		call AMSend.send(1, &packet, sizeof(radio_toss_msg_t));
		//dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }	
  }

}




