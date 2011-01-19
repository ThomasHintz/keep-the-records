var parentNames;
var parentIds;

$(document).ready(function() {
    $('#success').delay(5000).fadeTo('slow', 0, 'swing');

    $('input').attr('spellcheck', false).attr('autocomplete', false);

    $('#name').focus();

    $('#parent-name-2').blur(function() {
	if ($('#release-to').val() == "") {
	    $('#release-to').val($('#parent-name-1').val() + ', ' + $('#parent-name-2').val()); }});
    
    $('#name').blur(function() {
	if ($('#name').val() == '') {
	    $('#label-name').removeClass('hidden');
	    $('#name').removeClass('filled'); }
	else {
	    $('#label-name').addClass('hidden');
	    $('#name').addClass('filled'); }});

    $('#grade').blur(function() {
	var grade = $('#grade').val();
	
	if (grade == 'age-2-or-3') {
	    $('#club-level').val('Puggies'); }
	else if (grade == 'pre-k') {
	    $('#club-level').val('Cubbies'); }
	else if (grade == 'K' || grade == '1' || grade == '2') {
	    $('#club-level').val('Sparks'); }
	else if (grade == '3' || grade == '4' || grade == '5' || grade == '6') {
	    $('#club-level').val('TnT'); }
	else if (grade == '7' || grade == '8') {
	    $('#club-level').val('Trek'); }});

    $('#birthday').blur(function() {
	if ($('#birthday').val() != '') {
	    $('#birthday').addClass('filled'); }});

    $('input').change(function() {
	if ($(this).val() != '') { $(this).addClass('filled'); }
	else { $(this).removeClass('filled'); }});

    parentNames = $('#parent-names').val().split('|');
    parentIds = $('#parent-ids').val().split('|');
    $('#parent-name-1').autocomplete(parentNames); });