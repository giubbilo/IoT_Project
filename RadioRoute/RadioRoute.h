#ifndef RADIO_ROUTE_H
#define RADIO_ROUTE_H

typedef nx_struct radio_route_msg
{
	nx_uint8_t type;
	nx_uint8_t sender;
	nx_uint8_t dest;
	nx_uint8_t data; //data represents value or cost depending on the type message
}radio_route_msg_t;

typedef struct routing_table_entry
{
	uint16_t destAddress;
	uint16_t nextHop;
	uint16_t cost;
}routing_table_entry_t;

enum
{
	AM_RADIO_COUNT_MSG = 10,
};

#endif
