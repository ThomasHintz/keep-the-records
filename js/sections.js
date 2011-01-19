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

function getCookie(c_name)
{
    if (document.cookie.length>0)
    {
	c_start=document.cookie.indexOf(c_name + "=");
	if (c_start!=-1)
	{
	    c_start=c_start + c_name.length+1;
	    c_end=document.cookie.indexOf(";",c_start);
	    if (c_end==-1) c_end=document.cookie.length;
	    return unescape(document.cookie.substring(c_start,c_end));
	}
    }
    return "";
}


$(document).ready(function() {
    $('#filter').keyup(function() {
	MyUtil.selectFilter('clubbers', $('#filter').val());
	document.getElementById('clubbers').selectedIndex = 0; }); });

var lastSection = 0;
var lastChapter = 0;

function markSection(id) {
    $.ajax({type:'PUT',url:'/ajax/mark-section',success:function(response){loadClubberSections(response);},dataType: 'json',data:{'sid':getCookie('awful-cookie'),'clubber':$('#clubbers').val()[0],'book':$('#change-book').attr('selectedIndex'),'chapter':id.split('.')[0],'section':id.split('.')[1]}}); }

function loadClubberSections(response) {
    var bookNum = 0;
    $.each(response, function(id, html) {
	if (id == "books") {
	    var o = '';
	    for (var i = 0; i < html.length; i++) {
		o += '<option value="' + html[i] + '">' + html[i] + '</option>'; }
	    $('#change-book').html(o); }
	else if (id == "book-num") {
	    bookNum = html; }
	else if (id == "last-section") {
	    lastChapter = html[0];
	    lastSection = html[1];
	    $('#mark-section').attr('value', html[0] + '.' + html[1]); }
	else if (id == "name") {
	    $('#clubber-name').text(html); }
	else if (id == "sections") {
	    $('#sections-container').html(html);
	    $('.finished').click(function() { markSection($(this).attr('id')); });
	    $('.unfinished').click(function() { markSection($(this).attr('id')); }); }});

    $('#change-book').attr('selectedIndex', bookNum);
	  
    $('#default-info').addClass('hidden');
    $('#info-container').removeClass('hidden'); };