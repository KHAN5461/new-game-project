extends PanelContainer


# variables
var pawn_no:int =1
var wood_no:int =0
var cash_no:int =0
var meat_no:int =0
# checker
var overlap=false

#variables for actions
var build=false
var chop=false



# functions to add or sub the stats
func add_pawn():
	pawn_no+=3
func sub_pawn():
	pawn_no-=1
func add_wood():
	wood_no+=5
func sub_wood():
	wood_no-=1
func add_cash():
	cash_no+=1
func sub_cash():
	cash_no-=1
func add_meat():
	meat_no+=1
func sub_meat():
	meat_no-=1
