![Typing SVG](https://readme-typing-svg.demolab.com/?font=Fira+Code&weight=600&size=24&pause=1000&color=FF6B1A&center=true&vCenter=true&width=600&lines=A+wire+guided+missile+system%2C+shown+in+https%3A%2F%2Fkevinlabs.dev%2F)

A little rundown on the code, I had separated main functionalities into modules, however, this is an older version of the code (I shall update it with the modules, but it works identically to the current version)

Like a real TOW missile, which is a missile fired from tanks, pod's etc, an old system made by the US government, the tow stands for a tube launched optically tracked, wire-guided system, which is something I simulated here:

* Movement is all vectors, Velocity, thrust, gravity, and drag get added together every frame using the position to move the missile. Thrust just pushes it forward along its CFrame.LookVector,
* Like a real rocket firing. The target point comes from the player's mouse using Mouse.Hit.Position (or a raycast from the camera), and once guidance kicks in, the missile's velocity slowly turns toward that point each Heartbeat, so moving your mouse steers the missile mid-flight.
