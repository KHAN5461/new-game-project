# **scripts/entities/characters/lancer.gd**

extends ProgrammableUnit

## **Lancer (Cavalry Sheep Rider) unit. Features high speed, double-distance**

## **grid movement step execution, and linear charge pierce attacks.**

# **STREAMING\_CHUNK:Initializing nodes and variables...**

@onready var animation\_player: AnimationPlayer \= $AnimationPlayer

@onready var charge\_raycast: RayCast2D \= $ChargeRayCast

@onready var pierce\_hitbox: Area2D \= $PierceHitbox

const TILE\_SIZE: float \= 64.0

const CAVALRY\_SPEED\_MULTIPLIER: float \= 1.8

var is\_charging: bool \= false

# **STREAMING\_CHUNK:Setting up startup and restore hooks...**

func \_on\_unit\_ready() \-\> void:

is\_charging \= false

animation\_player.play("Lancer\_Idle")

func \_on\_state\_restored() \-\> void:

is\_charging \= false

animation\_player.play("Lancer\_Idle")

# **STREAMING\_CHUNK:Configuring custom cavalry physics layers...**

func \_configure\_physics\_layers() \-\> void:

super.\_configure\_physics\_layers()

\# Cavalry unit detects obstacles and enemies along their path  
charge\_raycast.collision\_mask \= 0  
charge\_raycast.set\_collision\_mask\_value(1, true) \# Layer 1: Terrain  
charge\_raycast.set\_collision\_mask\_value(3, true) \# Layer 3: Enemy Units  
charge\_raycast.set\_collision\_mask\_value(4, true) \# Layer 4: Obstacles

# **STREAMING\_CHUNK:Implementing primary compiler commands...**

func execute\_instruction(command: String, args: Array) \-\> void:

if is\_dead: return

match command:  
	"move\_forward":  
		\# Cavalry units default to moving 2 tiles per step unless specified  
		var steps \= args\[0\] if args.size() \> 0 else 2  
		await \_move\_by\_grid(steps)  
		  
	"turn\_right":  
		await \_rotate\_angle(90)  
		  
	"turn\_left":  
		await \_rotate\_angle(-90)  
		  
	"charge\_attack":  
		await \_execute\_charge\_pierce()

# **STREAMING\_CHUNK:Defining cavalry environment sensors...**

func eval\_sensor(sensor: String) \-\> bool:

if is\_dead: return false

match sensor:  
	"is\_path\_blocked":  
		charge\_raycast.target\_position \= Vector2(TILE\_SIZE \* 2, 0\)  
		charge\_raycast.force\_raycast\_update()  
		return charge\_raycast.is\_colliding()  
	"target\_in\_charge\_range":  
		return \_scan\_for\_enemies\_in\_line()  
return false

# **STREAMING\_CHUNK:Managing grid movement and sheep running animation...**

func \_move\_by\_grid(steps: int) \-\> void:

animation\_player.play("Lancer\_Run")

var dir \= Vector2.RIGHT.rotated(rotation)

var target\_pos \= global\_position \+ (dir \* TILE\_SIZE \* steps)

\# Faster tween curves to reflect the speed of cavalry mounts  
var tween \= create\_tween().set\_trans(Tween.TRANS\_QUAD).set\_ease(Tween.EASE\_OUT)  
tween.tween\_property(self, "global\_position", target\_pos, 0.22 \* steps)  
await tween.finished

animation\_player.play("Lancer\_Idle")

# **STREAMING\_CHUNK:Processing linear lance charge mechanics...**

func \_execute\_charge\_pierce() \-\> void:

is\_charging \= true

animation\_player.play("Lancer\_Charge")

var dir \= Vector2.RIGHT.rotated(rotation)  
var charge\_target \= global\_position \+ (dir \* TILE\_SIZE \* 3\) \# Charges forward exactly 3 tiles

\# Slide high-speed charge vector across the board  
var tween \= create\_tween().set\_trans(Tween.TRANS\_EXPO).set\_ease(Tween.EASE\_OUT)  
tween.tween\_property(self, "global\_position", charge\_target, 0.4)

\# Apply damage frames mid-glide  
await get\_tree().create\_timer(0.2).timeout  
\_apply\_charge\_strike\_damage()

await tween.finished  
is\_charging \= false  
animation\_player.play("Lancer\_Idle")

# **STREAMING\_CHUNK:Applying collision sweep damage to targets...**

func \_apply\_charge\_strike\_damage() \-\> void:

for body in pierce\_hitbox.get\_overlapping\_bodies():

if body.is\_in\_group("Enemies") and body.has\_method("take\_damage"):

body.take\_damage(35) \# High impact cavalry charge damage

func \_scan\_for\_enemies\_in\_line() \-\> bool:

charge\_raycast.target\_position \= Vector2(TILE\_SIZE \* 3, 0\)

charge\_raycast.force\_raycast\_update()

if charge\_raycast.is\_colliding():

var col \= charge\_raycast.get\_collider()

return col and col.is\_in\_group("Enemies")

return false

# **STREAMING\_CHUNK:Executing angular turn transitions...**

func \_rotate\_angle(degrees: float) \-\> void:

var tween \= create\_tween().set\_trans(Tween.TRANS\_QUAD).set\_ease(Tween.EASE\_IN\_OUT)

var target\_rot \= rotation\_degrees \+ degrees

tween.tween\_property(self, "rotation\_degrees", target\_rot, 0.18)

await tween.finished

# **STREAMING\_CHUNK:Handling cavalry death state animation...**

func \_on\_death() \-\> void:

animation\_player.play("Lancer\_Dead")

await get\_tree().create\_timer(1.2).timeout

super.\_on\_death()