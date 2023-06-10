#ifndef RADIO_TOSS_H
#define RADIO_TOSS_H

typedef nx_struct radio_toss_msg {
  	nx_uint8_t type;
  		/*
	* type = 0 -> ACK
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
} radio_toss_msg_t;

uint16_t indexAckReceived[8] = {0};
uint16_t indexConnAckReceived[8] = {0};

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif
