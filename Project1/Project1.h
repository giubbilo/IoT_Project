#ifndef PROJECT_1_H
#define PROJECT_1_H

typedef nx_struct msg
{
	nx_uint8_t type;
	/*
	* type = 1 -> CONN
	* type = 2 -> CONNACK
	* type = 3 -> SUB
	* type = 4 -> SUBACK
	* type = 5 -> PUB
	*/
	nx_uint8_t sender;
	nx_uint8_t dest;
	nx_uint8_t topic;
	/*
	* topic = 0 -> TEMPERATURE
	* topic = 1 -> HUMIDITY
	* topic = 2 -> LUMINOSITY
	*/
	nx_uint8_t payload; // Solo per i PUB message
}msg_t;

uint8_t indexConnReceived[8] = {0,0,0,0,0,0,0,0};
uint8_t indexConnAckReceived[8] = {0,0,0,0,0,0,0,0};

enum
{
	AM_RADIO_COUNT_MSG = 10,
};

#endif
