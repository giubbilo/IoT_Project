#ifndef PROJECT1_H
#define PROJECT1_H

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
	nx_uint8_t data;
	nx_uint8_t topic;
	/*
	* topic = 0 -> TEMPERATURE
	* topic = 1 -> HUMIDITY
	* topic = 2 -> LUMINOSITY
	*/
}msg_t;

uint16_t indexConnReceived[8] = {0};
uint16_t indexConnAckReceived[8] = {0};
uint16_t indexSubbedTopic[8] = {3, 3, 3, 3, 3, 3, 3, 3};
uint16_t indexSubSended[8] = {0};
uint16_t indexSubReceived[8] = {0};
uint16_t indexSubAckReceived[8] = {0};

enum
{
	AM_RADIO_COUNT_MSG = 6,
};

#endif
