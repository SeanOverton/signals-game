# Signals game

Space game made with lua/love2d

Download love2d to get started.

`love .` inside the root directory to run.

## For art
https://www.pixilart.com/draw
128 x 128px

## Todo

- ~~Organise code better, particularly around nodes. Make this a more generic object. Done~~
- ~~passengers also, done~~
- ~~Finish: passengers and empty nodes first, with UI, done~~
- ~~Main menu, done~~
- ~~More art assets for more nodes, generally update UI. more passegers~~
- ~~refactor nodes to be more extensible, use object... kinda?~~
- ~~refactor ship~~
- ~~UI for ship, done~~
- ~~Implement story, created custscenes to some extent? can add more here~~
- ~~Implement shop, and other node types~~
- ~~Implement ship upgrades (more effects on the situations)~~
    - animate these too
- ~~make nodes generally more interesting, see gpt response -> delay, animate some effects~~
    - slow them down, kinda done
    - cut scenes -> space to continue, cut scene
    - updated combat node, to have some real basic combat
    - story can offer a bit more lore... interaction
- marketing strategy -> pump out 3 content every day for 30 days (lets go for longer than this?)
    - note: balatro took 2 years to build... and they had a demo/wishlist up
    on steam for months. Earlier user feedback the better though
    - I think initially the marketing content is to drive some interest
    but also attract some loyal fans
    - note the devs blog for reference: https://localthunk.com/blog/balatro-timeline-3aarh
    - also this could be helpful as well https://howtomarketagame.com/


- realised it was going down a very manual path creating story and a lot of linear new nodes etc.
    - the original plan was to create combos/chains in the simple mechanics to drive lots of variations
    in runs and make it very scalable by just adding more passengers. This is now being revisited with the
    event system, animations/multipliers for resources to drive more interactions between the nodes/choices/
    passengers/rocket-build-upgrades
    - this has now become the main focus because this will become the CORE game mechanic before just scaling it out for more events/passengers etc.

- add more events to trigger effects of passengers, start animations
    - more animations in general
- improve whole world by generating it from seed up front:
    - ✅ TL;DR — How to Make a Random World Feel Cohesive
    - ~~Pre-generate the map (fixed seed),~~ done
    - Improve hints and minimap, hints added at least
    - Divide into regions, each with its own node biases, this will be effectively the levels/runs. If you win in world 1, you unlock galaxy 2 -> new characters etc.
    - Use visual and narrative transitions between regions.
    - Add clusters (micro-stories).
    - Leave breadcrumbs or trails for navigation?
    - Give ambient rules per region.
    - Create a final goal (rescue beacon or signal source).
    - partial hints for each direction... to actually make the direction choice have value
- more art assets, alot more, keep them consistent pixels
        - for all nodes, upgrades
- more cut-scenes (at start for more story/context)
- then just add more nodes, characters, make the map scale out
- more menu for signals/collectibles? settings?
- tutorial
- runs/archetypes
    - 🌌 OVERVIEW: “GALAXY RUNS” AS THE META STRUCTURE

Think of each galaxy as one self-contained run —
like a “sector” in FTL, a “biome” in Slay the Spire, or a “planet system” in Balatro.

Each galaxy has:

A theme (affects node distribution, visuals, and mechanics)

A goal (e.g., collect X signals, rescue a lost ship, defeat a boss)

A unique twist or rule (oxygen drains faster, traders are rare, anomalies mutate)

🧠 DESIGN PHILOSOPHY SHIFT

So now the structure looks like this:

Macro Loop: Complete galaxies → unlock next → build meta-progression
Meso Loop: Explore node grid → manage fuel/oxygen → optimize build
Micro Loop: Each node → short, reactive, choice-driven event with small mechanics

You now have three levels of engagement:

Immediate fun (moment-to-moment)

Mid-run experimentation (build synergies)

Long-term mastery (galaxy runs, unlocks)

That’s the same multi-scale design that makes Balatro, Slay the Spire, FTL, and Hades so sticky.

- progressive universes
