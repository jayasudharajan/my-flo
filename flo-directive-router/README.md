# Directive Router

The directive router services is in charge on receiving directives from different app like mobile app or user portal, validate them and send it right to the ICD device if it is not in forced sleep mode.
Also, it keeps track of the different directive sent to the devices using the API so we can then see if was executed or what was the state updated in the directive response service.

Some of the directives are:
- Open/Close Valve
- Upgrade the device
- Execute leak detection tests
  
