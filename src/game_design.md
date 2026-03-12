### Goals:
- Strategy Incremental Game?
- Maybe add roguelike aspects?
- 20+ hours of *interesting* gameplay (not just tedious achievement hunting)

### Implemented User Actions:
- Buying shop-slots
- Buying and placing buildings
- Moving Buildings to new locations
- Assigning People to buildings
- Rerolling Shop for new buildings
- Ending Turn (Shop -> Buildings -> Events)

### Buildings:

Castle      - Defends, collects taxes, king
Dwelling    - People's houses, more people
Farm        - Creates food, needs people to work
Market      - Trades things for different things
Necromancer - Summons undead? brings people back to life?
Ship        - Moves on water
Goblin Tent - Steals gold, stabs people

Ideas:
Resources: People, Food, Gold, Death

### Tiles:

Grass       - Solid, Biology, Plants
Blue Grass  - Solid, Biology, Plants
Stone       - Solid, Hard
Sand        - Solid, Soft, Hot
Water       - Liquid, Cold
Lava        - Liquid, Hot
Snow        - Solid, Cold, Soft
Asteroid    - Solid, Ores
Sun         - Gas, Hot

Ideas:
Traits: Phase, Hardness, Temperature, Organics?

### Events:

Fissure - Converts a line to lava with 'shake' effect

Meteor - Drops into an area in an explosion?
Tornado - Moves buildings around?
Cold Front/Snow - Converts tiles in an area to snow?
Rain - Boosts Grass/Converts stone to grass, sand to water?

### Boss Ideas: (each could have a unique board?)



- Weather - Blizzard: convert X tiles to snow per turn
- Weather - Meteor Swarm: lots of meteors falling each turn
- Inflation: Devalues money, everything is more expensive
- Crown-virus: Buildings can get infected and people inside risk dying
- Goblin King: lots of goblins (bigger tent, wears a crown)
- Goblinzilla: Big goblin, runs around and crushes buildings (and people)
- 

### Good
- winning
- number go up


Buildings cost: 1+ person, X+ gold,
Can add people but not remove them - Board People vs Babies, Babies carry over

Start: 0g, 5 babies

Lose condition:
- After X turns, a star/black hole takes a line of tiles out (destroys)
- X+1 turns, takes another line
- X+2 turns, the star/black hole sucks up all the tiles, player loses

#### Game Concept:
1. Player is given 
    - a board of tiles
    - # gold
    - # babies
    - # open shop slots
    - # to H events queued up 
    - # turns until 'rogue star' loss condition
2. Player must: 
    - 'escape' the board before all the tiles are consumed by the 'rogue star'
    - earn # gold to purchase an escape to another board (escape ships can cost different amounts of $$)
3. Player's Turn:
    - Can buy shop slots (permanent)
    - Can upgrade shop slots (board-locked)
    - Can reroll shop and buy/place buildings (board-locked)
    - Can assign 'babies' to buildings to improve/boost them (board locks the assigned babies)
    - Can move buildings and reassign people to other buildings
    - Decide when to end the turn
4. Pieces Activate
5. Events Activate/count down
6. [REPEAT UNTIL ESCAPE OR LOSS]

7. Escape:
    - choose a direction (NW/NE), a unique cost of gold assigned to each (representing difficulty)
    easier boards would be cheaper and have fewer rewards, harder would be more expensive and better
    - each direction eliminates a boss/buff from a list of options for last board
    - beating the last board is considered a 'win'

