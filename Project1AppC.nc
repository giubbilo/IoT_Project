#include "Project1.h"

configuration Project1AppC {}
implementation
{
	components MainC, Project1C as App;
	components new AMSenderC(AM_RADIO_COUNT_MSG);
	components new AMReceiverC(AM_RADIO_COUNT_MSG);
	components new TimerMilliC();
	components ActiveMessageC;
	  
	App.Boot -> MainC.Boot;
	App.Receive -> AMReceiverC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.MilliTimer -> TimerMilliC;
	App.Packet -> AMSenderC;
}
