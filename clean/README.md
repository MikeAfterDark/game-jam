# Requirements:

- Web build
[ WIP ] Figure out how UI's should work
    [X] TransitioningEffect - cleaned up into `function scene_transition(...)`
    [ ] options buttons, layout stuffs, ties into OPTIONS REVAMP
- Figure out background, colours, images, noise, anything
- Options revamp:
    - SFX, Music
    - Fullscreen/Windowed
    - Brightness?
    - Resolution multiplier? (factors of the pixel resolution, resizing = false, keeps pixels square)
    - Vsync
    - Controls
        - Kb-Mouse Keybinds
        - make sure to leave a way to have controller/whatever options
    - Game Options
        - Game specifics



[X] shooting feels inconsistennt 
    - firing on button press and not waiting 0.1s before first shot
[X] tutorial/Controls explained
    - Tutorial button in main menu, `state.tutorial`
    - level 0 is tutorial level
    - snake is slower in level 0
    - tutorial text ui
[X] Misc:
    - stop pausing during transition
    - player id ui to tutorial ui layer
