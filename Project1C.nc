/*
 * @authors Salvatore Gabriele Karra & Davide Giannubilo
 */

#include "Timer.h"
#include "Project1.h"
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define SERVER_IP "127.0.0.1"  // Localhost IP address
#define SERVER_PORT 1234      // Port number for the server

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
	
	int sockfd;
    struct sockaddr_in servaddr;
	
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
    if (locked) return;
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
				//dbg_clear("radio_send", " at time %s \n", sim_time_string());
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
						// for (i = 0; i < 8; ++i) { printf("%u ", indexConnAckReceived[i]); } printf("\n"); // Stampa CONNACK ricevuti correttamente
						if (indexSubSended[TOS_NODE_ID-2] == 0)
    					{ // If i don't have sended the SUB message i send it (QoS 0)
    						msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
    						indexSubSended[TOS_NODE_ID-2] == 1;
							msg->topic = TOS_NODE_ID%3;
      						msg->type = 2; // SUB TYPE
    						msg->dest = 1;
   							msg->sender = TOS_NODE_ID;
							if(msg->topic == 0) dbg("radio_send", "CONNECTED !!! Send a SUBSCRIBE with topic: TEMPERATURE\n");
							else if(msg->topic == 1) dbg("radio_send", "CONNECTED !!! Send a SUBSCRIBE with topic: HUMIDITY\n");
							else if(msg->topic == 2) dbg("radio_send", "CONNECTED !!! Send a SUBSCRIBE with topic: LUMINOSITY\n");
							call AMSend.send(1, &packet, sizeof(msg_t));
							//dbg_clear("radio_send", " at time %s \n", sim_time_string());
    					}
					}
					// SUBACK received
					if(msg -> type == 3 && indexSubAckReceived[msg -> dest - 2] == 0)
					{
						if(msg->topic == 0) dbg("radio_send", "Received SUBACK from PAN coordinator! Node: %d subbed to topic: TEMPERATURE!\n", TOS_NODE_ID - 1);
						else if(msg->topic == 1) dbg("radio_send", "Received SUBACK from PAN coordinator! Node: %d subbed to topic: HUMIDITY!\n", TOS_NODE_ID - 1);
						else if(msg->topic == 2) dbg("radio_send", "Received SUBACK from PAN coordinator! Node: %d subbed to topic: LUMINOSITY!\n", TOS_NODE_ID - 1);
						indexSubAckReceived[TOS_NODE_ID - 2] = TOS_NODE_ID - 1;
						indexSubbedTopic[TOS_NODE_ID-2] = msg->topic;
						 for (i = 0; i < 8; ++i) { printf("%u ", indexSubAckReceived[i]); } printf("\n"); // stampa SUBACK ricevuti correttamente
						 for (i = 0; i < 8; ++i) { printf("%u ", indexSubbedTopic[i]); } printf("\n"); // stampa topic subbati correttamente
					}
					if(indexConnAckReceived[msg -> dest - 2] != 0 && indexSubAckReceived[msg -> dest - 2] != 0)
					{ 
						msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
						msg->topic = TOS_NODE_ID%3; //sample but not randomic
						msg->data = TOS_NODE_ID%4*10; //sample but not randomic
     					msg->type = 4; // SUB TYPE
   						msg->dest = 1;
  						msg->sender = TOS_NODE_ID;
						if(msg->topic == 0) dbg("radio_rec", "PUBBLISH, topic: TEMPERATURE payload: %d\n", msg->data);
						else if(msg->topic == 1) dbg("radio_rec", "PUBBLISH, topic: HUMIDITY payload: %d\n", msg->data);
						else if(msg->topic == 2) dbg("radio_rec", "PUBBLISH, topic: LUMINOSITY payload: %d\n", msg->data);
						call AMSend.send(1, &packet, sizeof(msg_t));
						//dbg_clear("radio_send", " at time %s \n", sim_time_string());
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
    					call AMSend.send(msg->dest, bufPtr, sizeof(msg_t));
    	 				// for (i = 0; i < 8; ++i) { printf("%u ", indexConnReceived[i]); } printf("\n"); // stampa CONN ricevuti correttamente
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
    	 			if(msg -> type == 4)
    				{	
    					if(msg->topic == 0) dbg("radio_rec", "PAN -> received PUB from node: %d, to topic: TEMPERATURE with payload: %d\n", msg -> sender - 1, msg->data);
						else if(msg->topic == 1) dbg("radio_rec", "PAN -> received PUB from node: %d, to topic: HUMIDITY with payload: %d\n", msg -> sender - 1, msg->data);
						else if(msg->topic == 2) dbg("radio_rec", "PAN -> received PUB from node: %d, to topic: LUMINOSITY with payload: %d\n", msg -> sender - 1, msg->data);
						for (i = 0; i < 8; ++i) 
						{ 
							if(indexSubbedTopic[i] == msg->topic)
							{
								dbg("radio_rec", "Forward to node: %d\n", indexSubAckReceived[i]);
								call AMSend.send(indexSubAckReceived[i], bufPtr, sizeof(msg_t));
								
    						}
    						
						}
						dbg("radio_rec", "Forward to node-red \n");
								// Send the message to Node-RED TCP node
        						// Create socket
        						sockfd = socket(AF_INET, SOCK_STREAM, 0);
        						if (sockfd == -1) {
           	 						dbgerror("tcp", "Socket creation failed\n");
            						return;
        						}

        						// Set server address
        						servaddr.sin_family = AF_INET;
        						servaddr.sin_addr.s_addr = inet_addr(SERVER_IP);
        						servaddr.sin_port = htons(SERVER_PORT);

        						// Connect to the server
       							if (connect(sockfd, (struct sockaddr*)&servaddr, sizeof(servaddr)) != 0) {
           							dbgerror("tcp", "Connection with the server failed\n");
            						close(sockfd);
            						return;
        						}

        						// Send the message
        						if (send(sockfd, msg, sizeof(msg_t), 0) == -1) {
            						dbgerror("tcp", "Failed to send message\n");
            						return;
        						}
    					close(sockfd);
    	 		}
    		}
    	}
    	return bufPtr;
	}

	event void AMSend.sendDone(message_t* bufPtr, error_t error)
  	{
  		msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
  		if (&packet == bufPtr && error == SUCCESS) {
      		//dbg("radio_send", "Packet sent...\n");
      		locked = TRUE;	
  		}
  		if ((indexConnReceived[TOS_NODE_ID-2] == 0 || indexConnAckReceived[TOS_NODE_ID-2] == 0)  && TOS_NODE_ID != 1) 
  		{ // If i'm not the PAN and i don't have received the CONNACK or my CONN message did not arrived to the PAN i resend it (QoS 1)
			dbg("radio_send", "PACKET LOST...send AGAIN CONN to PAN coordinator\n");	
			msg->type = 0; // CONN TYPE
   			msg->sender = TOS_NODE_ID;
			call AMSend.send(1, &packet, sizeof(msg_t));
			//dbg_clear("radio_send", " at time %s \n", sim_time_string());
    	}
  	}
}

