#ifndef PROJECT1_H
#define PROJECT1_H

#define MESSAGE_BUFFER 5   

typedef nx_struct Msg
{
  	nx_uint8_t type;
  	/*
	* type = 0 -> CONN
	* type = 1 -> CONNACK
	* type = 2 -> SUB
	* type = 3 -> SUBACK
	* type = 4 -> PUB
	*/
	nx_uint8_t sender;
	nx_uint8_t dest;
	nx_uint8_t data; // Field containing the value to send to Node-RED
	nx_uint8_t topic;
	/*
	* topic = 0 -> TEMPERATURE
	* topic = 1 -> HUMIDITY
	* topic = 2 -> LUMINOSITY
	*/
}msg_t;

uint8_t counterPub = 0;
uint16_t indexConnReceived[8] = {0}; // Containing which node have sent and delivered a CONN message
uint16_t indexConnAckReceived[8] = {0}; // Containing which node have received a CONNACK message
uint16_t indexSubReceived[8] = {0}; // Containing which node have received a SUB message
uint16_t indexSubAckReceived[8] = {0}; // Containing which node have received a SUBACK message
uint16_t indexSubbedTopic[8] = {3, 3, 3, 3, 3, 3, 3, 3}; // Containing the topic of each node
uint16_t buffer[MESSAGE_BUFFER][5] = {{0, 0, 0, 0, 0}, 
									  {0, 0, 0, 0, 0}, 
									  {0, 0, 0, 0, 0}, 
									  {0, 0, 0, 0, 0},
									  {0, 0, 0, 0, 0}}; // Containing the topic of each node

enum
{
	AM_RADIO_COUNT_MSG = 6,
};

#endif

