# Signature Tool

The notion of subsystem is used in Simulink to represent systems inside systems in order to provide hierarchical modeling. A Simulink subsystem has inports (explicit links to the subsystem), and outports (explicit links from the subsystem). We view inports and outports as the explicit interface of the subsystem. However, there are hidden (implicit) data dependencies in Simulink’s subsystems. Hidden dependencies originate due to two Simulink data mechanisms:

1. Data Store Memory/Read/Write
1. Goto/From blocks

The Signature Tool extracts the signature of a Simulink subsystem. A signature represents the interface of a Simulink subsystem, making the data flow into and out of the subsystem explicit. The tool identifies two useful signatures for a subsystem: strong signature and weak signature. The strong signature identifies the data mechanisms that are accessed by the subsystem or any of its children. The weak signature identifies the data mechanisms that a subsystem can access (those which are declared higher up in the hierarchy), but is not necessarily using. The Signature Tool can be used to either explicitly include the signatures in the model itself, or export the signatures into a text/tex/docx file.

<img src="imgs/Cover.png" width="650">

## User Guide
For installation and other information, please see the [User Guide](doc/Signature_UserGuide.pdf).
