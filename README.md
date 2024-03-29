# Project1 - LIGHTWEIGHT PUBLISH-SUBSCRIBE APPLICATION PROTOCOL
Internet of Things course | 2° semester a.y. 22/23 | Politecnico di Milano

## Specification
Design and implementation in TinyOS a lightweight publish-subscribe application protocol similar to MQTT protocol and test it with simulations
on a star-shaped network topology composed of 8 client nodes connected to a PAN coordinator. The PAN coordinator acts as an MQTT broker.

The following features need to be implemented:
1. Connection: upon activation, each node sends a CONNECT message to the PAN coordinator. The PAN coordinator replies with a CONNACK message. If the PAN coordinator receives messages from not yet connected nodes, such messages are ignored. Be sure to handle retransmissions if msgs get lost (retransmission if CONN or CONNACK is lost).
2. Subscribe: after connection, each node can subscribe to one among these three topics: TEMPERATURE, HUMIDITY, LUMINOSITY. In order to subscribe, a node sends a SUBSCRIBE message to the PAN coordinator, containing its node ID and the topics it wants to subscribe to (use integer topics). Assume the subscriber always use QoS=0 for subscriptions. The subscribe message is acknowledged by the PANC with a SUBACK message. (handle retransmission if SUB or SUBACK is lost)
3. Publish: each node can publish data on at most one of the three aforementioned topics. The publication is performed through a PUBLISH message with the following fields: topic name, payload (assume that always QoS=0). When a node publishes a message on a topic, this is received by the PAN and forwarded to all nodes that have subscribed to a particular topic.
4. Test the implementation in the simulation environment in TOSSIM, with at least 3 nodes subscribing to more than 1 topic. The payload of PUBLISH messages on all topics is a random number.
5. The PAN Coordinator (Broker node) should be connected to NodeRED, and periodically transmit data received on the topics to ThingsSpeak through MQTT. Thingspeak must show one chart for each topic on a public channel.

## Tools used
- TinyOS 
  - nesC
- Tossim
  - Python
- Node-RED
- ThingSpeak

## How to run it
1. Open the terminal
2. Start Node-RED launching `node-red` command or install it if you do not have it
3. Open you browser and go to `localhost:1880`
4. Import the flow on Node-RED from `Node-RED_flow.pdf`
5. Open [our ThingSpeak public channel](https://thingspeak.com/channels/2185815) where you can see the charts with the latest PUBLISH messages done by the nodes
6. Open another terminal window
7. Move to `src/`
8. Launch this command `make micaz sim`
9. Once the compile procedure is done, launch `RunSimulationScript.py`

## Credits
Developed by Davide Giannubilo & Salvatore Gabriele Karra | June 2023
