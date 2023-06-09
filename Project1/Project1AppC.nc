#include "Project1.h"

configuration Project1AppC {}
implementation
{
	/***** COMPONENTS *****/
  	components MainC, Project1C as App;
  	components new AMSenderC(AM_RADIO_COUNT_MSG);
  	components new AMReceiverC(AM_RADIO_COUNT_MSG);
  	components new TimerMilliC() as Timer0;
  	components new TimerMilliC() as Timer1;
  	components ActiveMessageC;
    
  	/***** INTERFACES *****/
    App.Boot -> MainC.Boot;
  	App.AMSend -> AMSenderC;
  	App.Packet -> AMSenderC;
  	App.Receive -> AMReceiverC;
  	App.AMControl -> ActiveMessageC;
  	App.Timer0 -> Timer0;
  	App.Timer1 -> Timer1;
}
