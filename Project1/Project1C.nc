#include "Timer.h"
#include "Project1.h"

module Project1C @safe()
{
	uses
	{
		/***** INTERFACES *****/
		interface Boot;
		interface Packet;
		interface AMSend;
		interface Receive;
		interface SplitControl as AMControl;
		interface Timer<TMilli> as Timer0;
		interface Timer<TMilli> as Timer1;
  	}
}

implementation
{	
	message_t packet;
  
	// Variables to store the message to send
	message_t queued_packet;
	uint16_t queue_addr;
	//uint16_t time_delays[7] = {61,173,267,371,479,583,689}; //Time delay in milli seconds
  	uint16_t time_delays[7] = {0,0,0,0,0,0,0};
	bool locked = FALSE;
	
	uint8_t i;
  
	bool actual_send (uint16_t address, message_t* packet);
	bool generate_send (uint16_t address, message_t* packet, uint8_t type);
  	
	bool generate_send (uint16_t address, message_t* packet, uint8_t type)
	{
		/*
	    * Function to be used when performing the send after the receive message event.
	    * It store the packet and address into a global variable and start the timer execution to schedule the send.
	    * It allow the sending of only one message for each REQ and REP type
	    * @Input:
	    *		address: packet destination address
	    *		packet: full packet to be sent (Not only Payload)
	    *		type: payload message type
	    *
	    * MANDATORY: DO NOT MODIFY THIS FUNCTION
	    */
	  	
	  	if(call Timer0.isRunning())
	  	{
	  		return FALSE;
	  	}
	  	else
	  	{
		  	if(type == 1)
		  	{
		  		call Timer0.startOneShot( time_delays[TOS_NODE_ID-1] );
		  		queued_packet = *packet;
		  		queue_addr = address;
		  	}
				else if(type == 2)
				{
					call Timer0.startOneShot( time_delays[TOS_NODE_ID-1] );
					queued_packet = *packet;
					queue_addr = address;
				}
					else if(type == 0)
					{
						call Timer0.startOneShot( time_delays[TOS_NODE_ID-1] );
						queued_packet = *packet;
						queue_addr = address;	
					}
  		}
  		return TRUE;
	}
	
	bool actual_send(uint16_t address, message_t* packet)
  	{
		if(locked)
		{
			return FALSE;
		}
			else
			{
				msg_t* msg = (msg_t*)call Packet.getPayload(packet, sizeof(msg_t));
				if(msg == NULL)
				{
					dbg("radio", "Error, empty message!\n");
					return FALSE;
				}
				if(call AMSend.send(address, packet, sizeof(msg_t)) == SUCCESS)
				{
					//dbg("radio", "OKKKKKKKKKKKKKKKKKKKKKKKKKKK\n");
					locked = TRUE;
					return TRUE;
				}
			}
  	}
  
  	event void Timer0.fired()
  	{
	  	
	  	actual_send(queue_addr, &queued_packet);
	  	//dbg("radio", "Timer 0 started!\n");
	}
  
  	event void Boot.booted()
  	{
    	dbg("boot","Application booted!\n");
    	call AMControl.start();
  	}

  	event void AMControl.startDone(error_t err)
  	{
		if(err == SUCCESS)
		{
      		dbg("boot","Radio ON on node %d!\n", TOS_NODE_ID);
      		call Timer1.startOneShot(0);
      	}
			else
			{
				dbgerror("boot", "Radio failed to start, retrying...\n");
				call AMControl.start();
			}
  	}

  	event void AMControl.stopDone(error_t err)
  	{
    	dbg("boot", "Radio stopped!\n");
  	}
  
  	event void Timer1.fired()
	{
		//dbg("timer", "Timer started!\n");
		if(TOS_NODE_ID != 0)
		{			
			msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
			msg -> type = 1; // CONN
			msg -> dest = 0; // PANC
			msg -> sender = TOS_NODE_ID;
			dbg("radio_send", "Connecting to the PANC \n");
			generate_send(msg -> dest, &packet, msg -> type);
			//locked = TRUE;
		}
	}

  	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) 
  	{
  		msg_t* msg = (msg_t*)payload;
		if(len != sizeof(msg_t)) 
		{
			return;
		}
		else 
		{
			
			// dbg("radio_rec", "msg->sender: %d, msg->dest: %d, msg->type: %d\n", msg->sender, msg->dest, msg->type);
			if(msg -> type == 2)
			{
				dbg("radio_rec", "Received CONNACK from PANC, node: %d connected !!!\n", TOS_NODE_ID);
				indexConnAckReceived[TOS_NODE_ID - 1] = TOS_NODE_ID;
				for (i = 0; i < 8; ++i) { printf("%u ", indexConnAckReceived[i]); } printf("\n"); // stampa connack ricevuti correttamente				
			}
			
			if(TOS_NODE_ID == 0 && msg -> type == 1)
			{
				dbg("radio_rec", "Received CONN from node: %d\n", msg -> sender);
				indexConnReceived[msg -> sender-1] = msg -> sender;
				dbg("radio_send", "Send CONNACK to node: %d\n", msg -> sender);	
				msg -> type = 2; // CONNACK TYPE
				msg -> dest = msg->sender;
				//msg -> sender = 0;
				
				generate_send(msg -> sender, bufPtr, 2);
				/*for (i = 0; i < 8; ++i)
				{
					printf("%u ", indexConnReceived[i]);
				}
				printf("\n"); // stampa ack ricevuti correttamente
			*/}
			return bufPtr;
		}
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error)
  {
  		msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
  		if(&queued_packet == bufPtr && error == SUCCESS)
	  	{
		  	dbg("radio_send", "Packet sent 1...\n");
		  	locked = FALSE;
	  	}
	  	if(&packet == bufPtr && error == SUCCESS)
	  	{
		  	dbg("radio_send", "Packet sent 2...\n");
		  	locked = FALSE;
	  	}
	  	if(indexConnReceived[TOS_NODE_ID-1] == 0 && TOS_NODE_ID != 0)
	  	{
			dbg("radio_send", "Packet lost! Send again CONN msg to PANC\n");	
			generate_send(0, bufPtr, 1);
			//dbg_clear("radio_send", " at time %s \n", sim_time_string());
			locked = FALSE;
		}
		if(indexConnAckReceived[msg -> dest - 1] == 0 && TOS_NODE_ID == 0)
	  	{
			dbg("radio_send", "Packet lost! Send again CONNACK msg to PANC\n");	
			generate_send(msg -> dest, bufPtr, 2);
			//dbg_clear("radio_send", " at time %s \n", sim_time_string());
			locked = FALSE;
		}
  }
} // Implementation END

