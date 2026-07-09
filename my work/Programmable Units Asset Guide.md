# **🎨 Tiny Swords Free Pack Asset Unit Analysis & Implementation**

This guide maps the visual sprite-sheet configurations of the **Tiny Swords (Free Pack)** directly to our custom Multi-Language Compiler & Transactional Game State Machine.

## **📂 Sprite Sheet Atlas Mapping**

Each faction contains 5 programmable troop classes: **Pawn**, **Warrior**, **Archer**, **Lancer**, and **Monk**. All sheets are organized in horizontal grids of ![][image1] px frames.

┌────────────────────────────────────────────────────────┐  
│  Frame 0 \[Idle\]  │  Frame 1 \[Idle\]  │  Frame 2 \[Idle\]  │ ...  
├────────────────────────────────────────────────────────┤  
│  Frame 6 \[Run\]   │  Frame 7 \[Run\]   │  Frame 8 \[Run\]   │ ...  
└────────────────────────────────────────────────────────┘

### **1\. Blue / Red / Yellow / Purple Pawn (Worker)**

* **Idle / Run Carry States:** Pawns have unique sheets representing what resource they are carrying or which tool they hold.  
* **Asset Sheets:**  
  * Pawn\_Idle.png / Pawn\_Run.png (Standard/Empty)  
  * Pawn\_Idle Axe.png / Pawn\_Run Axe.png (Holds woodsman axe)  
  * Pawn\_Idle Gold.png / Pawn\_Run Gold.png (Holds heavy gold bag)  
  * Pawn\_Idle Wood.png / Pawn\_Run Wood.png (Carries harvested timber)  
  * Pawn\_Idle Hammer.png / Pawn\_Run Hammer.png (Holds build mallet)  
* **Animation Prefix Strategy:** We resolve animations dynamically inside our scripts by concatenating current carry states:  
  "Pawn\_Idle\_" \+ carry\_state (e.g., "Pawn\_Idle\_Wood", "Pawn\_Run\_Axe").

### **2\. Warrior (Melee Knight)**

* **Combat States:** Uses a high-impact horizontal sword slash layout.  
* **Asset Sheets:**  
  * Warrior\_Idle.png (6 frames)  
  * Warrior\_Run.png (6 frames)  
  * Warrior\_Attack1.png / Warrior\_Attack2.png (Down-right slashes \- 6 frames each)  
  * Warrior\_Guard.png (Active shield stance, reduces damage by ![][image2])

### **3\. Archer (Ranged Sniper)**

* **Ranged Fire State:** Standard horizontal shooting cycle. Archer releases projectile logic on exactly **Frame 4** of the Shoot cycle.  
* **Asset Sheets:**  
  * Archer\_Idle.png (6 frames)  
  * Archer\_Run.png (6 frames)  
  * Archer\_Shoot.png (8 frames \- fires arrow)

### **4\. Monk (Support Cleric)**

* **Healing Channels:** Emits active magical channeling sequences.  
* **Asset Sheets:**  
  * Idle.png / Run.png (6 frames each)  
  * Heal.png (6 frames, plays looping channeling sequence)  
  * Heal\_Effect.png (Particle animation overlaid on target positions)

## **⚙️ Programmatic Animation & Interaction Protocol**

To align physics with code execution, every animation instruction is structured as an **asynchronous transaction**:

1. **Block Call**: The interpreter matches a statement, e.g. move\_forward().  
2. **State Handshake**: The interpreter calls await target\_unit.execute\_instruction("move\_forward", args).  
3. **Visual Run**: The unit transitions animation from Idle to Run.  
4. **Physics Slide**: A Tween slides the Character body across the grid by ![][image3] px.  
5. **Completion Signal**: The animation player resets, the tween signals finished, and the script returns control back to the interpreter to process the next instruction.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFcAAAAYCAYAAACPxmHVAAADNUlEQVR4Xu2XS2gTURSGJyS+0KJoYix53CQNxgZBIbhQFBFctLQ+UFGhOxWKUBERnxtBEB8giA+UIhYVcae4kKLdCG668rFxU7ooZONewY3U/8+ck94MeSA4FuX+8DH3ce6Zc8/ce2fG85ycnJycnP4TRY0x3SSXyx0mKE9om22YSqXSaHsmjIInpFAorLVtstnsfWEM/Z8IyoPojgihC/NYQXDvLbi+IigP2DaIezlB+z3wUHgK2+2ENpVKZQFB/OdkzmQS9asknU4vsX02iJ0w2krgsI9IQurJTSQSywj63qJtH2G7jkP9RTwe7yIoP4LdHkIb1HcI1Uwms57Y9w9LiKtC8vn8Btz7PUF9l2US00WAvovWuILxF9cExiatBXdbE40FtAr1D8KI5bNRLrkhJteWBmQCyWWAEuQMkrOJBOynNHEo3wSXCW14TMhxUuXkAhNsECaxDnZHCKpRu0+3MMafLJVKXcTubyUuCvh7R+x7M3FomxZqi4WSeU8R2O/EdUAYZ1IJzCJGjkfE/FjHtlWr5OKaF6Z5QxKw/5qVVdzosZYw3Q2fNdFBG1v6IDHmlK4U7K6V8H2JoH1NcEw7tUqunLWTBD6HtV3mPSMMabsteTAfCRbU7mB/U7nkzkNyPXnLo+8sAjlPUI/heoHA7pt9XKgQhMGYNwR2G+2+ToLPXnBXuKHHQtCuk1oll0LbfoL2B8VicRFBnIfQ9lOoHxeUPmy03wEjxPNz01ltkquKWCtrL2wHCey+4FogNOLqEm7lRAyqXC4vJAGfTWX+QnJV2BlF9B0gWCDbOB+ZU30nSlJPE87Z898J0WQyuXTOUxu55M5PcmPE+F8C+jZnEvUzZVRteD4a+VrI+W//mh/4Pchg7YCbyXp4oZ65FOonCPqueHL0obwZvCYc60kScd9htPUL3RqnafcphkGLYXBGGBd+mLk/sX5Pbgzba+C40IfAxggnTD/i6yWYbUK10wtNHsYf+RRj3AL/Ir+TnP+dXpurxHqMoHzdWljPjb9resXPUWG2BQ3ncoNcckNM7m8q2tPTs1phXfhXVVs0/DHAFk8SHkNBIycnJycnJyencPQLufS2POw/Sb0AAAAASUVORK5CYII=>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACYAAAAYCAYAAACWTY9zAAACHElEQVR4Xu2VzUtUURjGr6BlaETJNMp83PmSwSFxMUYtgtrMQqEWraI2hUTiUhRnEdE2SARFURArglbtrEWrZuXGRS38N/ofen52XjqeZgTB4C7uCz/ufc95z3Mezrz3TBSlkUb3KBQK03Ecb0GpVGrncrk8+DX5fL6m+SVQ2u/P/bc4d2MqvqbCTceeiVcqlStWo3xCm31wtIvF4hpks9mh6M8G/cq3RRNk8obq3oDWrmvsPej9U7lcjuGvgyBk6BKo+KMEboHyceVHoMVTViPRd2wGrNX8smMuk8kMAzp2SnofE4+BemnfBuUzJ110icQa02Z3HN+q1ep1kOiIpvoc1FRAggduszE3fh+Uf1Y6AHrfkPGbgAnNtwBNzS1As9mk9vRQ4aLjl3gCEn2g51tAxHpG+c8exjp2YpyUDO2AxpdqtdpFUP7M+gpNetfv338iscYkvAISOdTzKrhe+Q6YPIuxUN/vK6/3uEqegta3wjXHEbtT8sWdsQ5gmg8AlP/oYeyrNhkEXzvsK82/ADQjd71gzt79tck15v1MX+r1+mUIf0rrB+X7YgJYaxuJ1ydE3Rdd8vqKQQwZVqia+V5tcOxWm61qwXNQ8aPYa34rVP5QvATda5N67oJtbKH1d4HTDMbvgcZfcZrgTqxrJNaYRZ8VhxesH3bsMpPFdHhZNhqNCzI7C+Fc5DQ1NxO7fw0ZGw1q0kgjjUTGb+S08K83X1W7AAAAAElFTkSuQmCC>

[image3]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABUAAAAYCAYAAAAVibZIAAABOUlEQVR4Xu2SrUoEURiGj0FRMAgyisw/E4QpCiN4BQbDgk3QOzAIgmASqzdg0aAXICLIgphsdqNtwaTZYPN52W9hflyFhd00Hzycn/f93nPOMM61NWrleT4jiqKYrmsj17+hQRDMxXF8KqIoumG8E8y36l6V+R8Enk5F1CkC8SJJkl2h01nfCtbnlQbnpgRBh+hfYjKhbBSC5lcMqciybGlwWMVMhWG4IfDtwbNohLK5b3zAsUjTdA3jvVDAwOv7/iL6gbD5BEPZOBGI7xgDUdvvep43L+zAWNh6aGhHIPZgRZRD+dZvsCNYP6JfCubXjJ8C7YlxW4wvlKesCjZefgtl3aVpVvTf1i/z6iK9xvOd/Xc0HSGeCeabCrPA9bI5sUK7gm/RuKkbU2i5YUHwOZaH/fxttfV3/QAvXZmbZYEiogAAAABJRU5ErkJggg==>