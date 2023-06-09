#include "Timer.h"
#include "RadioRoute.h"

#define NEIGHBOURS 2

module RadioRouteC @safe()
{
	uses
	{
		/***** INTERFACES *****/
		interface Boot;
		interface Leds;
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
	routing_table_entry_t routingTable[7];
	
	message_t packet;
  
	// Variables to store the message to send
	message_t queued_packet;
	uint16_t queue_addr;
	uint16_t time_delays[7] = {61,173,267,371,479,583,689}; //Time delay in milli seconds
	
	uint16_t leader_code[8] = {1,0,7,7,5,1,0,5};
	uint16_t index_led[8];
	
	uint8_t num_msg = 0;
	
	bool trovato;
	uint8_t check;
	uint8_t t;
	uint8_t j;
	uint8_t z;
	uint8_t i;
	uint8_t k;
	uint8_t p;
	uint8_t q;
	uint8_t r;
	uint8_t b;
	uint8_t pos;
	uint8_t resto;
	uint8_t destinazione;
	uint8_t firstdestination;
	uint8_t count_path_received_node_1;
	uint8_t min_count_path_received_node_1 = 255;
	uint8_t sender_min_count_path_received_node_1;
  
	bool route_req_sent = FALSE;
	bool route_rep_sent = FALSE;
	bool locked = FALSE;
	bool fine = FALSE;
	bool already_sent = FALSE;
  
	bool actual_send (uint16_t address, message_t* packet);
	bool generate_send (uint16_t address, message_t* packet, uint8_t type);
  	bool routeTableEmpty();
  	void fillRoutingTable();
  	uint8_t routeTableCheck(uint16_t dest);
	void ledSequence();  
  
  	// Create an array containing remainders of divisions by 3
  	void ledSequence()
  	{
		k = 0;	  		
		while(k < 8)
		{
			resto = leader_code[k] % 3;
			index_led[k] = resto;
			k = k + 1;
		}
  	}
 	
  	// Fill the routing table with 0s
  	void fillRoutingTable()
  	{
		i = 0;
		while(i < 7)
		{
			routingTable[i].destAddress = 0;
			routingTable[i].nextHop = 0;
			routingTable[i].cost = 0;
			i = i + 1;
		}
  	}
  	
  	/* 
  	* Check if the routing table is empty 
  	* If the first row is empty, then the whole table is empty
	* (I supposed that the routing table is populated starting from the first row)
	*/
	bool routeTableEmpty()
  	{
  		if(routingTable[0].destAddress == 0)
  		{
  			return TRUE;
  		}
			else
			{
				return FALSE;
			}
  	}
  	
  	/* 
  	* Che if the destination node is present in the table
  	* If it is in the table, I will return the index of its position, otherwise
	* I will return a value that cannot be occur, 9, since the MAX number of
	* rows is 7.
	*/
	uint8_t routeTableCheck(uint16_t dest)
  	{
  		p = 0;
  		while(p < 7)
  		{
  			if(routingTable[p].destAddress == dest)
  			{	
  				return p;	
  			}
  			if(p == 6)
  			{
  				return 9;
  			}
  			p = p + 1;
  		}
  	}
  	
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
		  	if(type == 1 && !route_req_sent)
		  	{
		  		route_req_sent = TRUE;
		  		call Timer0.startOneShot( time_delays[TOS_NODE_ID-1] );
		  		queued_packet = *packet;
		  		queue_addr = address;
		  	}
				else if(type == 2 && !route_rep_sent)
				{
					route_rep_sent = TRUE;
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
		/*
		* Implement here the logic to perform the actual send of the packet using the tinyOS interfaces
		*/
		if(locked)
		{
			return FALSE;
		}
			else
			{
				radio_route_msg_t* rrm = (radio_route_msg_t*)call Packet.getPayload(packet, sizeof(radio_route_msg_t));
				if(rrm == NULL)
				{
					dbg("radio", "Error, empty message!\n");
					return FALSE;
				}
				if(call AMSend.send(address, packet, sizeof(radio_route_msg_t)) == SUCCESS)
				{
					locked = TRUE;
					return TRUE;
				}
			}
  	}
  
  	event void Timer0.fired()
  	{
	  	/*
	  	* Timer triggered to perform the send.
	  	* MANDATORY: DO NOT MODIFY THIS FUNCTION
	  	*/
	  	actual_send(queue_addr, &queued_packet);
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
      		call Timer1.startOneShot(5000);
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
		dbg("timer", "Timer 1 started!\n");
		// Fill the routing table with 0 for each row/column
		fillRoutingTable();
		// If I am the first node I can start the cycle by sending a message to my neighbours
		if(TOS_NODE_ID == 1)
		{
			radio_route_msg_t* rrm = (radio_route_msg_t*)call Packet.getPayload(&packet, sizeof(radio_route_msg_t));
			rrm -> type = 1;
			rrm -> dest = 7;
			generate_send(AM_BROADCAST_ADDR, &packet, rrm -> type);
			dbg("radio_send", "Sending packet from node 1...\n");
		}
	}

  	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len)
  	{
		/*
		* Parse the receive packet
		* Implement all the functionalities
		* Perform the packet send using the generate_send function if needed
		* Implement the LED logic and print LED status on Debug
		*/
		
		radio_route_msg_t* rrm = (radio_route_msg_t*) payload;	
		if(len != sizeof(radio_route_msg_t))
		{
			return bufPtr;
		}	
					
		if(TOS_NODE_ID == 6) // Start LED part for node 6
		{
			ledSequence(); // Create an array with the remainders
			/* 
			* We used the operation "modulo 8" because, since the index of the array starts from 0 and
			* at the last digit it will be 7
			*/
			if(index_led[num_msg % 8] == 0)
			{
				call Leds.led0Toggle();
				num_msg = num_msg + 1;
				dbg_clear("radio_rec", "\n");
				dbg("radio_rec", "Resto 0 - Node %d\n", TOS_NODE_ID);
				dbg("led_0", "Led 0 status %u\n", (call Leds.get() & LEDS_LED0) > 0);
     			dbg("led_1", "Led 1 status %u\n", (call Leds.get() & LEDS_LED1) > 0);
      			dbg("led_2", "Led 2 status %u\n", (call Leds.get() & LEDS_LED2) > 0);
			}
				else if(index_led[num_msg % 8] == 1)
				{
					call Leds.led1Toggle();
					num_msg = num_msg + 1;
					dbg_clear("radio_rec", "\n");
					dbg("radio_rec", "Resto 1 - Node %d\n", TOS_NODE_ID);
					dbg("led_0", "Led 0 status %u\n", (call Leds.get() & LEDS_LED0) > 0);
					dbg("led_1", "Led 1 status %u\n", (call Leds.get() & LEDS_LED1) > 0);
					dbg("led_2", "Led 2 status %u\n", (call Leds.get() & LEDS_LED2) > 0);
				}
					else if(index_led[num_msg % 8] == 2)
					{
						call Leds.led2Toggle();
						num_msg = num_msg + 1;
						dbg_clear("radio_rec", "\n");
						dbg("radio_rec", "Resto 2 - Node %d\n", TOS_NODE_ID);
						dbg("led_0", "Led 0 status %u\n", (call Leds.get() & LEDS_LED0) > 0);
						dbg("led_1", "Led 1 status %u\n", (call Leds.get() & LEDS_LED1) > 0);
						dbg("led_2", "Led 2 status %u\n", (call Leds.get() & LEDS_LED2) > 0);
					}
			dbg("radio", "Messages received and sent from node 6: %d\n\n", num_msg);
		} // End LED part
				
		// ROUTE_REQ received
		if(rrm -> type == 1 && !fine)
		{
			dbg("radio_rec", "Received a ROUTE_REQ at time %s\n", sim_time_string());
			check = routeTableCheck(rrm -> dest);
			/*
			* The requested node is NOT in the routing table and the receiver is not the requested node
			*/
			if(check == 9 && TOS_NODE_ID != rrm -> dest)
			{
				rrm -> sender = TOS_NODE_ID;
				generate_send(AM_BROADCAST_ADDR, bufPtr, 1);
				dbg("radio_send", "Sending a ROUTE_REQ in broadcast\n");
			}
			/* 
			* The receiver is the node requested
			*/
			if(TOS_NODE_ID == rrm -> dest)
			{
				rrm -> type = 2;
				rrm -> sender = TOS_NODE_ID;
				rrm -> data = 1; // Cost
				dbg("radio_send", "I am the destination, set cost to 1 and send a ROUTE_REPLY in broadcast\n");
				generate_send(AM_BROADCAST_ADDR, bufPtr, rrm -> type);
			}
			/* 
			* The requested node is in the routing table, so the function routeTableCheck
			* will return a value between 0 and 6
			*/
			if(check <= 6 && check >= 0) 
			{
				j = 0;	
				trovato = FALSE;
				while(j < 7 && trovato == FALSE)
				{
					if(routingTable[j].destAddress == rrm -> dest)
					{
						rrm -> data = routingTable[j].cost + 1; // +1 to the cost in the routing table
						trovato = TRUE;
					}
					j = j + 1;
				}
				rrm -> type = 2;
				rrm -> sender = TOS_NODE_ID;
				generate_send(AM_BROADCAST_ADDR, bufPtr, rrm -> type);
				dbg("radio_send", "Sending a ROUTE_REP in broadcast\n");
			}
		} // ROUTE_REQ finish point
				
		// ROUTE_REPLY received
		if(rrm -> type == 2  && !fine && TOS_NODE_ID != rrm -> dest)
		{
			dbg("radio_rec", "Received a ROUTE_REPLY at time %s\n", sim_time_string());
			check = routeTableCheck(rrm -> dest);
			
			// Node 1 receives a ROUTE_REPLY and sends its message to node 7
			if(TOS_NODE_ID == 1 && routeTableCheck(7))
			{
				count_path_received_node_1 = count_path_received_node_1 + 1;
				if(rrm -> data < min_count_path_received_node_1)
				{
					min_count_path_received_node_1 = rrm -> data;
					sender_min_count_path_received_node_1 = rrm -> sender;
				}
				if(count_path_received_node_1 == NEIGHBOURS)
				{
					firstdestination = sender_min_count_path_received_node_1;
					dbg("radio_send", "<<<<< Route found, cost: %d, send packet from 1 to %d \n", min_count_path_received_node_1, firstdestination);
					// Send the real data message hop-by-hop
					rrm -> type = 0;
					rrm -> dest = 7;
					rrm -> data = 5;
					rrm -> sender = TOS_NODE_ID;
					generate_send (firstdestination, bufPtr, 0);
				}
			}
				else if(check == 9) // == 9 means that the node requested is NOT in my routing table
				{
					t = 0;
					while(routingTable[t].destAddress != 0) // Founding the first empty row
					{
						t = t + 1;
					}
					//Updating the routing table
					routingTable[t].destAddress = rrm -> dest;
					routingTable[t].nextHop = rrm -> sender;
					routingTable[t].cost = rrm -> data;
					rrm -> data = rrm -> data + 1; //Increment cost by 1
					rrm -> sender = TOS_NODE_ID;
					generate_send(AM_BROADCAST_ADDR, bufPtr, 2);
					dbg("radio_send", "Sending a ROUTE_REPLY in broadcast\n");
				}
					else // The requested node is my routing table
					{
						z = 0;
						while(routingTable[z].destAddress != rrm -> dest)
						{
							z = z + 1;
						}
						if(rrm -> data < routingTable[z].cost)
						{
							routingTable[z].cost = rrm -> data;
							routingTable[z].nextHop = rrm -> sender;
							rrm -> data = rrm -> data + 1; //Increment cost by 1
							rrm -> sender = TOS_NODE_ID;
							generate_send(AM_BROADCAST_ADDR, bufPtr, 2);
						}
					}									
		} //ROUTE_REPLY finish part
		
		// DATA message received
		if(rrm -> type == 0 && !fine)
		{	
			trovato = FALSE;
			if(TOS_NODE_ID == 7)
			{
				fine = TRUE;
				dbg_clear("radio_rec", "\n");
				dbg("radio_rec", "----- Il pacchetto è arrivato a destinazione -----\n");
				dbg("radio_rec", "Type: %d\n", rrm -> type);
				dbg("radio_rec", "Sender: %d\n", rrm -> sender);
				dbg("radio_rec", "Receiver: %d\n", rrm -> dest);
				dbg("radio_rec", "Value: %d\n\n", rrm -> data);
			}
			r = 0;
			while(r < 7 && trovato == FALSE)
			{
				if(routingTable[r].destAddress == rrm -> dest)
				{
					trovato = TRUE;
					rrm -> sender = TOS_NODE_ID;
					destinazione = routingTable[r].nextHop;
					generate_send(destinazione , bufPtr, 0); // Invio al destinatario
					dbg("radio_send", "<<<<< Sending packet in the route found from %d to %d \n", TOS_NODE_ID, routingTable[r].nextHop);
				}
				r = r + 1;
			}					
		} // DATA message finish par
		return bufPtr;			
	}

  	event void AMSend.sendDone(message_t* bufPtr, error_t error)
  	{
		/* 
		* This event is triggered when a message is sent 
		* Check if the packet is sent 
		*/
		
		if (&queued_packet == bufPtr && error == SUCCESS)
		{
			dbg("radio_send", "Packet sent successfully at time %s \n", sim_time_string());
			locked = FALSE;
		}
			else
			{
				dbgerror("radio_send", "Send error !!!\n");
			}
  	}
} // Implementation END
