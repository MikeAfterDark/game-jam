Theme: Space Whales
Special Object: PCB (Printed Circuit Board)

2D grid-based puzzle game about 'connecting' PCBs.

A Whale is X units long, and has sides with various traits:

- Solder: allows a connection to be connected
- Sealant: permanently closes a connection
- Connection: connects to the whale, locks the whale shape & to the PCB, whale can only move 'forward' until release
  There can be multiple whales, player can only control one at a time, 'connect' to another whale to swap control

PCBs are connected squares with connections on the sides:

- Can be moved (pushed/pulled by whale/other PCBs)
- all sides with connections must either be:
  - sealed
  - connected to other PCBs
  - connected to the whales

'Puzzle' completion is when all sides are accounted for and all PCBs are connected.

Undo/Redo stack.

Level 1:

- Whales: 1 [length=3, connections=1]
- PCBs: 1
- Connections: 1
  Solution: whale moves into position with PCB and 'connects'

Level 2:

- Whales: 1 [length=3, connections=0]
- PCBs: 2
- Connections: 2
  Solution: whale moves the PCBs together and 'connects' them

Level 3:

- Whales: 2 [length=2, connections=1] [length=3, connections=2]
- PCBs: 1
- Connections: 2
  Solution: whale 1 connects to whale 2, whale 2 pulls whale 1 and connects to pcb
