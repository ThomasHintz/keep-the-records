MyUtil = new Object();
MyUtil.selectFilterData = new Object();
MyUtil.selectFilter = function(selectId, filter) {
    var list = document.getElementById(selectId);
    if(!MyUtil.selectFilterData[selectId]) { //if we don't have a list of all the options, cache them now'
	MyUtil.selectFilterData[selectId] = new Array();
	for(var i = 0; i < list.options.length; i++) MyUtil.selectFilterData[selectId][i] = list.options[i];
    }
    list.options.length = 0;   //remove all elements from the list
    for(var i = 0; i < MyUtil.selectFilterData[selectId].length; i++) { //add elements from cache if they match filter
	var o = MyUtil.selectFilterData[selectId][i];
	if(o.text.toLowerCase().indexOf(filter.toLowerCase()) >= 0) list.add(o, null);
    }
}

$(document).ready(function() {
    $('#filter').keyup(function() {
	MyUtil.selectFilter('clubbers', $('#filter').val());
	document.getElementById('clubbers').selectedIndex = 0; });

    $('#clubbers').live('change keypress', function () { $('#clubber-name').text($('#clubbers :selected').text()); }); });