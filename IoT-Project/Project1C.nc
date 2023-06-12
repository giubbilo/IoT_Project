/*
 * @authors Salvatore Gabriele Karra & Davide Giannubilo
 */

#include "Timer.h"
#include "Project1.h"

module Project1C @safe()
{
	uses 
	{
		interface Boot;
		interface Receive;
		interface AMSend;
		interface Timer<TMilli> as MilliTimer;
		interface SplitControl as AMControl;
		interface Packet;
	}	
}

implementation
{
	message_t packet;
  	uint8_t i = 0;

  	bool locked;
  
  	event void Boot.booted() 
  	{
    	dbg("boot","Application booted\n");
    	call AMControl.start();
  	}

  	event void AMControl.startDone(error_t err)
  	{
    	if(err == SUCCESS)
    	{
    		if(TOS_NODE_ID == 1) 
    		{	
    			dbg("radio","Radio ON on PAN coordinator!\n");
      		}	
      			else
      			{	
      				dbg("radio","Radio ON on node %d!\n", TOS_NODE_ID-1);
				}      	
      		call MilliTimer.startPeriodic(250);
    	}
    	else
    	{
      		dbgerror("radio", "Radio failed to start, retrying...\n");
      		call AMControl.start();
    	}
  	}

  	event void AMControl.stopDone(error_t err)
  	{
  		dbg("boot", "Radio stopped!\n");
  	}
  
  	event void MilliTimer.fired()
  	{
		if(locked) return;
			else
			{
		  		msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
		  		if(msg == NULL)
		  		{
					return;
		  		}
		  		if(TOS_NODE_ID != 1 && indexConnReceived[TOS_NODE_ID - 2] == 0)
		  		{
		  			msg -> sender = TOS_NODE_ID;
		  			msg -> type = 0; // CONN TYPE
		  			msg -> dest = 1;
		  			call AMSend.send(msg -> dest, &packet, sizeof(msg_t));
					dbg("radio_send", "Try to connect to PAN coordinator. Sending a CONN message\n");	
		  		}
			}
  	}

  	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len)
  	{
    	if (len != sizeof(msg_t)) return;
    		else
    		{
    			msg_t* msg = (msg_t*)payload;
    			// dbg("radio_rec", "msg->sender: %d, msg->dest: %d, msg->type: %d\n", msg->sender, msg->dest, msg->type);
    			if(TOS_NODE_ID != 1) // I am a node 
    			{
    				// CONNACK received
    				if(msg -> type == 1 && indexConnAckReceived[msg -> dest - 2] == 0) 
    				{
						dbg("radio_rec", "Received CONNACK from PAN coordinator! Node: %d connected!\n", TOS_NODE_ID - 1);
						indexConnAckReceived[TOS_NODE_ID - 2] = TOS_NODE_ID - 1;
						//for (i = 0; i < 8; ++i) { printf("%u ", indexConnAckReceived[i]); } printf("\n"); // Stampa CONNACK ricevuti correttamente
						
					}
					// SUBACK received
					if(msg -> type == 3 && indexSubAckReceived[msg -> dest - 2] == 0)
					{
						dbg("radio_rec", "Received SUBACK from PAN coordinator! Node: %d subbed!\n", TOS_NODE_ID - 1);
						indexSubAckReceived[TOS_NODE_ID - 2] = TOS_NODE_ID - 1;
						//for (i = 0; i < 8; ++i) { printf("%u ", indexSubAckReceived[i]); } printf("\n"); // stampa SUBACK ricevuti correttamente
					}
    			}
    			if(TOS_NODE_ID == 1) // I am the PAN
    			{
    				// CONN received
    				if(msg -> type == 0)
    				{
    					dbg("radio_rec", "PAN -> received CONN from node: %d\n", msg -> sender - 1);
   		 				indexConnReceived[msg -> sender - 2] = msg -> sender - 1;
    					dbg("radio_send", "PAN -> sending CONNACK to node: %d\n", msg -> sender - 1);	
    					msg -> type = 1; // CONNACK TYPE
    					msg -> dest = msg -> sender;
    					msg -> sender = 1;
    					call AMSend.send(msg -> dest, bufPtr, sizeof(msg_t));
    	 				for (i = 0; i < 8; ++i) { printf("%u ", indexConnReceived[i]); } printf("\n"); // stampa CONN ricevuti correttamente
    	 			}
    	 			// SUB received
    				if(msg -> type == 2)
    				{
    					dbg("radio_rec", "PAN -> received SUB from node: %d\n", msg -> sender - 1);
    					indexSubReceived[msg -> sender - 2] = msg -> sender - 1;
    					dbg("radio_send", "PAN -> sending SUBACK to node: %d\n", msg -> sender - 1);	
    					msg -> type = 3; // SUBACK TYPE
    					msg -> dest = msg -> sender;
    					msg -> sender = 1;
    					call AMSend.send(msg -> dest, bufPtr, sizeof(msg_t));
    					// for (i = 0; i < 8; ++i) { printf("%u ", indexSubReceived[i]); } printf("\n"); // stampa SUB ricevuti correttamente
    	 			}
    			}
    		}
    	return bufPtr;
	}

	event void AMSend.sendDone(message_t* bufPtr, error_t error)
  	{
  		msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
  		if (&packet == bufPtr && error == SUCCESS)
  		{
      		//dbg("radio_send", "Packet sent... from node: %d\n", TOS_NODE_ID-1);
      		locked = TRUE;	
  		}
  		if(indexConnReceived[TOS_NODE_ID - 2] == 0 && TOS_NODE_ID != 1)
  		{
			dbg("radio_send", "PACKET LOST! Sending again a CONN message to PAN\n");
			msg -> type = 0; // CONN TYPE
	   		msg -> sender = TOS_NODE_ID;
	   		msg -> dest = 1;
			call AMSend.send(msg -> dest, &packet, sizeof(msg_t));
    	}
  		if(TOS_NODE_ID != 1 && indexConnAckReceived[TOS_NODE_ID - 2] == 0 && indexConnReceived[TOS_NODE_ID - 2] != 0)
  		{ 
	   		msg -> type = 1;
	   		msg -> sender = 1;
	   		msg -> dest = TOS_NODE_ID;
	   		dbg("radio_send", "PACKET LOST! Sending again a CONNACK message\n");
	   		call AMSend.send(msg -> dest, &packet, sizeof(msg_t)); // Sending a CONNACK
    	}
    	if(TOS_NODE_ID != 1 && indexSubAckReceived[TOS_NODE_ID - 2] == 0 && indexSubReceived[TOS_NODE_ID - 2] != 0 && indexConnAckReceived[TOS_NODE_ID - 2] != 0 && indexConnReceived[TOS_NODE_ID - 2] != 0)
  		{ 
	   		msg -> type = 3;
	   		msg -> sender = 1;
	   		msg -> dest = TOS_NODE_ID;
	   		dbg("radio_send", "PACKET LOST! Sending again a SUBACK message\n");
	   		call AMSend.send(msg -> dest, &packet, sizeof(msg_t)); // Sending a SUBACK
    	}
    	if(TOS_NODE_ID != 1 && indexSubReceived[TOS_NODE_ID - 2] == 0  && indexConnAckReceived[TOS_NODE_ID - 2] != 0 && indexConnReceived[TOS_NODE_ID - 2] != 0)
		{				
			msg -> topic = TOS_NODE_ID % 3;
		 	msg -> type = 2; // SUB TYPE
			msg -> dest = 1;
			msg -> sender = TOS_NODE_ID;
			if(msg -> topic == 0) dbg("radio_send", "Sending a SUBSCRIBE message to topic: TEMPERATURE\n");
			else if(msg -> topic == 1) dbg("radio_send", "Sending a SUBSCRIBE message to topic: HUMIDITY\n");
			else if(msg -> topic == 2) dbg("radio_send", "Sending a SUBSCRIBE message to topic: LUMINOSITY\n");
			call AMSend.send(msg -> dest, &packet, sizeof(msg_t));
		}	
  	}
}

