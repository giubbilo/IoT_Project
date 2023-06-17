/*
 * @authors Salvatore Gabriele Karra & Davide Giannubilo
 */

#include "Timer.h"
#include "Project1.h"
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define SERVER_IP "127.0.0.1"  // Localhost IP address
#define SERVER_PORT 1234       // Port number for the server
#define MAX_PUB 1

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
		interface Random;
	}	
}

implementation
{
	message_t packet;
	
	// Socket for tcp connection to Node-red
	int sockfd;
    struct sockaddr_in servaddr;
    
    // Variables for iterate through the arrays
	uint8_t i = 0;
  	uint8_t k = 0;
  	
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
		  		// Sending a CONN to PAN
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
    			if(TOS_NODE_ID != 1) // I am a node 
    			{
    				// CONNACK received
    				if(msg -> type == 1 && indexConnAckReceived[TOS_NODE_ID - 2] == 0) 
    				{
    					msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
						dbg("radio_rec", "Received CONNACK! Node %d connected\n", TOS_NODE_ID - 1);
						indexConnAckReceived[TOS_NODE_ID - 2] = TOS_NODE_ID - 1;
						//for (i = 0; i < 8; ++i) { printf("%u ", indexConnAckReceived[i]); } printf("\n"); // CONNACK received correctly
						msg -> topic = (TOS_NODE_ID - 1) % 3; 
  						msg -> type = 2; // SUB TYPE
						msg -> dest = 1;
						msg -> sender = TOS_NODE_ID;
						if(msg -> topic == 0) dbg("radio_send", "Node %d is sending a SUB to topic TEMPERATURE\n", TOS_NODE_ID - 1);
						else if(msg -> topic == 1) dbg("radio_send", "Node %d is sending a SUB to topic HUMIDITY\n", TOS_NODE_ID - 1);
						else if(msg -> topic == 2) dbg("radio_send", "Node %d is sending a SUB to topic LUMINOSITY\n", TOS_NODE_ID - 1);
						call AMSend.send(msg -> dest, &packet, sizeof(msg_t));
					}
					// SUBACK received
					if(msg -> type == 3 && indexSubAckReceived[TOS_NODE_ID - 2] == 0)
					{
						if(msg -> topic == 0) dbg("radio_rec", "Received SUBACK! Node %d subscribed to topic TEMPERATURE\n", TOS_NODE_ID - 1);
						else if(msg -> topic == 1) dbg("radio_rec", "Received SUBACK! Node %d subscribed to topic HUMIDITY\n", TOS_NODE_ID - 1);
						else if(msg -> topic == 2) dbg("radio_rec", "Received SUBACK! Node %d subscribed to topic LUMINOSITY\n", TOS_NODE_ID - 1);
						indexSubAckReceived[TOS_NODE_ID - 2] = TOS_NODE_ID - 1;
						indexSubbedTopic[TOS_NODE_ID - 2] = msg -> topic;
						//for (i = 0; i < 8; ++i) { printf("%u ", indexConnAckReceived[i]); } printf("\n"); // CONNACK received correctly
						//for (i = 0; i < 8; ++i) { printf("%u ", indexSubAckReceived[i]); } printf("\n"); // SUBACK received correctly
						//for (i = 0; i < 8; ++i) { printf("%u ", indexSubbedTopic[i]); } printf("\n"); // Topics of the nodes subscribed
					}
					if(indexConnAckReceived[TOS_NODE_ID - 2] != 0 && indexSubAckReceived[TOS_NODE_ID - 2] != 0)
					{ 
						msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
						msg -> topic = (TOS_NODE_ID - 1) % 3;
						msg -> data = call Random.rand16() % 31 + 10; // Random Value
     					msg -> type = 4; // PUB TYPE
   						msg -> dest = 1;
  						msg -> sender = TOS_NODE_ID;
						if(msg -> topic == 0) dbg("radio_send", "Node %d is sending a PUB to topic TEMPERATURE with payload: %d°C\n", TOS_NODE_ID - 1, msg -> data);
						else if(msg -> topic == 1) dbg("radio_send", "Node %d is sending a PUB to topic HUMIDITY with payload: %d%\n", TOS_NODE_ID - 1, msg -> data);
						else if(msg -> topic == 2) dbg("radio_send", "Node %d is sending a PUB to topic LUMINOSITY with payload: %d lux\n", TOS_NODE_ID - 1, msg -> data);
						call AMSend.send(1, &packet, sizeof(msg_t));
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
    	 				//for(i = 0; i < 8; ++i) { printf("%u ", indexConnReceived[i]); } printf("\n"); // CONN received correctly
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
    					if(call AMSend.send(msg -> dest, bufPtr, sizeof(msg_t)) != SUCCESS)
    					{
							dbg("radio_send", "Packet lost, send again...\n");
							call AMSend.send(msg -> dest, bufPtr, sizeof(msg_t));
						}
						//for(i = 0; i < 8; ++i) { printf("%u ", indexConnReceived[i]); } printf("\n"); // CONN received correctly
    					//for(i = 0; i < 8; ++i) { printf("%u ", indexSubReceived[i]); } printf("\n"); // SUB received correctly
    	 			}
    	 			// PUB received
    	 			if(msg -> type == 4)
    				{	
    					for(i = 0; i < MESSAGE_BUFFER; i++)
    					{
    						if(buffer[i][2] == 0) // Find an empty row in the buffer to store the message
    						{
								buffer[i][0] = msg -> type;
								buffer[i][1] = msg -> sender;
								buffer[i][2] = msg -> dest;
								buffer[i][3] = msg -> data;
								buffer[i][4] = msg -> topic;
								break;
							}
    					}
    					if(msg -> topic == 0) dbg("radio_rec", "PAN -> received PUB from node %d to topic TEMPERATURE with payload: %d°C\n", msg -> sender - 1, msg -> data);
						else if(msg -> topic == 1) dbg("radio_rec", "PAN -> received PUB from node %d to topic HUMIDITY with payload: %d%\n", msg -> sender - 1, msg -> data);
						else if(msg -> topic == 2) dbg("radio_rec", "PAN -> received PUB from node %d to topic LUMINOSITY with payload: %d lux\n", msg -> sender - 1, msg -> data);
						for (i = 0; i < 8; ++i) // Forward to node that subbed to the topic of the publish
						{ 
							if(indexSubbedTopic[i] == msg -> topic)
							{
								dbg("radio_rec", "Forwarding PUB to node: %d\n", indexSubAckReceived[i]);
								call AMSend.send(indexSubAckReceived[i] + 1, bufPtr, sizeof(msg_t));	
    						}	
						}
						// Take messages from buffer
				  		msg -> type = buffer[0][0];
						msg -> sender = buffer[0][1];
						msg -> dest = buffer[0][2]; 
						msg -> data = buffer[0][3];
				 		msg -> topic = buffer[0][4]; 
				 		if(msg -> type != 0)
				 		{
							dbg("radio_rec", "Sending PUB messages to Node-RED\n");
							// Send the message to Node-RED TCP node
							// Create socket
							sockfd = socket(AF_INET, SOCK_STREAM, 0);
							if(sockfd == -1)
							{
								dbg("error", "Socket creation failed!\n");
								return;
							}
							// Set server address
							servaddr.sin_family = AF_INET;
							servaddr.sin_addr.s_addr = inet_addr(SERVER_IP);
							servaddr.sin_port = htons(SERVER_PORT);
							// Connect to the server
							if(connect(sockfd, (struct sockaddr*)&servaddr, sizeof(servaddr)) != 0)
							{
								dbg("error", "Connection with the server failed!\n");
								close(sockfd);
								return;
							}
							// Send the message
							if(send(sockfd, msg, sizeof(msg_t), 0) == -1)
							{
								dbg("error", "Failed to send message!\n");
								return;
							}
							// for(i=0; i<MESSAGE_BUFFER; i++) {for(k=0; k<5; k++) { printf("%u ", buffer[i][k]); } printf("\n");} printf("\n");	// Print the buffer
							// Empty the buffer by deleting the message alredy send
							for(i = 1; i < MESSAGE_BUFFER; i++)
							{
								for (k = 0; k < 5; k++)
								{
									buffer[i - 1][k] = buffer[i][k];
							  	}
							}
							close(sockfd);
							sleep(16); // It is 16 because ThingSpeak can refresh only every 15s
						}			
    	 			}
    			}
    		}
    	return bufPtr;
	}

	event void AMSend.sendDone(message_t* bufPtr, error_t error) // Handle retrasmission if packet lost
  	{
  		msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
  		//dbg("radio", "\nsono il nodo %d\n", TOS_NODE_ID - 1);
  		if(&packet == bufPtr && error == SUCCESS)
  		{
      		//dbg("radio_send", "Packet sent...\n");
      		locked = TRUE;	
  		}
  		if((indexConnReceived[TOS_NODE_ID - 2] == 0 || indexConnAckReceived[TOS_NODE_ID - 2] == 0)  && TOS_NODE_ID != 1) 
  		{	
  			// If I'm not the PAN and I don't have received the CONNACK or my CONN message did not arrived to the PAN, I have to resend it
			dbg("radio_send", "Packet lost! Sending again a CONN to PAN coordinator\n");	
			msg -> type = 0; // CONN TYPE
   			msg -> dest = 1;
   			msg -> sender = TOS_NODE_ID;
			call AMSend.send(msg -> dest, &packet, sizeof(msg_t));
    	}
    	if((indexSubReceived[TOS_NODE_ID - 2] == 0 || indexSubAckReceived[TOS_NODE_ID - 2] == 0)  && TOS_NODE_ID != 1 && indexConnAckReceived[TOS_NODE_ID - 2] != 0) 
  		{	
			// If I'm not the PAN and I don't have received the SUBBACK or my SUB message did not arrived to the PAN, I have to resend it
			dbg("radio_send", "Packet lost! Sending again a SUB to PAN coordinator\n");	
			msg -> topic = (TOS_NODE_ID - 1) % 3;
			msg -> type = 2; // SUB TYPE
			msg -> dest = 1;
		   	msg -> sender = TOS_NODE_ID;
			call AMSend.send(msg -> dest, &packet, sizeof(msg_t));
		}
  	}
} // END implementation

