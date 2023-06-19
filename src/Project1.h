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

uint16_t indexConnReceived[8] = {0}; // Contains which node has received a CONN message
uint16_t indexConnAckReceived[8] = {0}; // Contains which node has received a CONNACK message
uint16_t indexSubReceived[8] = {0}; // Contains which node has received a SUB message
uint16_t indexSubAckReceived[8] = {0}; // Contains which node has received a SUBACK message
// Contains the subscribed topic of each node. Filled with 3 because we cannot have a topic that has "3" as integer
uint16_t indexSubbedTopic[8] = {3, 3, 3, 3, 3, 3, 3, 3}; 
// Contains PUB messages
// 5x5 because we have 5 variables in our msg struct and 5 rows because it's enough to contain messages. It's like a queue.
uint16_t buffer[MESSAGE_BUFFER][5] = {{0, 0, 0, 0, 0}, 
									  {0, 0, 0, 0, 0}, 
									  {0, 0, 0, 0, 0}, 
									  {0, 0, 0, 0, 0},
									  {0, 0, 0, 0, 0}};

enum
{
	AM_RADIO_COUNT_MSG = 6,
};

#endif
