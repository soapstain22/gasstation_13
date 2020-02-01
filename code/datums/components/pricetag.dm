/datum/component/pricetag
	var/datum/bank_account/owner = null
	var/profit_ratio = 1

/datum/component/pricetag/Initialize(_owner,_profit_ratio)
	if(_owner)
		owner = _owner
	if(_profit_ratio)
		profit_ratio = _profit_ratio
	if(isitem(parent))
		RegisterSignal(parent, COMSIG_ITEM_SOLD, .proc/split_profit)

/datum/component/pricetag/proc/split_profit(var/item_value)
	var/price = item_value
	if(price)
		owner.adjust_money(price*(profit_ratio/100))

