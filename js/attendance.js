function pointsMinus() {
    $('#points-today').text(parseInt($('#points-today').text()) - 1);
    $('#points-total').text(parseInt($('#points-total').text()) - 1); }

function pointsPlus() {
    $('#points-today').text(parseInt($('#points-today').text()) + 1);
    $('#points-total').text(parseInt($('#points-total').text()) + 1); }

$(document).ready(function() {
    $.ajaxSetup({ cache: false });
    $.ajaxSetup({ timeout: 60000, error: function (jqxhr, msg, err) {
	if (msg == 'timeout') {
	    alert('The server could not be reached, check your network connection. If this message persists, and' +
		  ' the rest of the site functions correctly, please let me know at support@keeptherecords.com'); }
	else {
	    alert('There has been an unexpected error. Please check your network connection and reload the page.' +
		  ' If the error persists, please let me know at support@keeptherecords.com');
            throw new Error("no server response"); }
    } });

	$('#clubber-names').selectable({ 'distance': 100000 });
	$("#clubber-names li").click(function() {
		$(this).addClass("selected").siblings().removeClass("selected");
	});

	var allClubberRows = $('.select-clubber-name');

	$('#filter').keyup(function() {
		var filter = $('#filter').val();
		allClubberRows.each(function(i, e) {
			if ($(e).text().toLowerCase().indexOf(filter.toLowerCase()) >= 0) {
				$(e).show();
			} else {
				$(e).hide();
			}
		});
	});

    $('#present').click(function() {
		if ($('#present').val() == "true") { $('#present').val("false"); pointsMinus(); }
		else { $('#present').val("true"); pointsPlus(); }
		$('#present').toggleClass('selected'); });
    $('#bible').click(function() {
		if ($('#bible').val() == "true") { $('#bible').val("false"); pointsMinus(); }
		else { $('#bible').val("true"); pointsPlus(); }
		$('#bible').toggleClass('selected'); });
    $('#handbook').click(function() {
		if ($('#handbook').val() == "true") { $('#handbook').val("false"); pointsMinus(); }
		else { $('#handbook').val("true"); pointsPlus(); }
		$('#handbook').toggleClass('selected'); });
    $('#uniform').click(function() {
		if ($('#uniform').val() == "true") { $('#uniform').val("false"); pointsMinus(); }
		else { $('#uniform').val("true"); pointsPlus(); }
		$('#uniform').toggleClass('selected'); });
    $('#extra').click(function() {
		if ($('#extra').val() == "true") { $('#extra').val("false"); pointsMinus(); }
		else { $('#extra').val("true"); pointsPlus(); }
		$('#extra').toggleClass('selected'); });
    $('#sunday-school').click(function() {
		if ($('#sunday-school').val() == "true") { $('#sunday-school').val("false"); pointsMinus(); }
		else { $('#sunday-school').val("true"); pointsPlus(); }
		$('#sunday-school').toggleClass('selected'); });
    $('#dues').click(function() {
		if ($('#dues').val() == "true") { $('#dues').val("false"); pointsMinus(); }
		else { $('#dues').val("true"); pointsPlus(); }
		$('#dues').toggleClass('selected'); });
    $('#on-time').click(function() {
		if ($('#on-time').val() == "true") { $('#on-time').val("false"); pointsMinus(); }
		else { $('#on-time').val("true"); pointsPlus(); }
		$('#on-time').toggleClass('selected'); });
    $('#friend').click(function() {
		if ($('#friend').val() == "true") { $('#friend').val("false"); pointsMinus(); }
		else { $('#friend').val("true"); pointsPlus(); }
		$('#friend').toggleClass('selected'); }); });

function loadClubberInfo(response) {
    $('.attendance-saving-notifier').hide();
    $('#clubber-name-container').removeClass('cubbies').removeClass('sparks').removeClass('tnt').removeClass('trek');
    $.each(response, function(id, html) {
	if (id == "present") { if (html == false) { $('#present').removeClass('selected'); $('#present').val("false"); }
			     else { $('#present').addClass('selected'); $('#present').val("true"); }}
	else if (id == "bible") { if (html == false) { $('#bible').removeClass('selected'); $('#bible').val("false"); }
			     else { $('#bible').addClass('selected'); $('#bible').val("true"); }}
	else if (id == "handbook") { if (html == false) { $('#handbook').removeClass('selected');
							$('#handbook').val("false"); }
			     else { $('#handbook').addClass('selected'); $('#handbook').val("true"); }}
	else if (id == "uniform") { if (html == false) { $('#uniform').removeClass('selected');
						       $('#uniform').val("false"); }
			     else { $('#uniform').addClass('selected'); $('#uniform').val("true"); }}
	else if (id == "friend") { if (html == false) { $('#friend').removeClass('selected'); $('#friend').val("false"); }
			     else { $('#friend').addClass('selected'); $('#friend').val("true"); }}
	else if (id == "extra") { if (html == false) { $('#extra').removeClass('selected'); $('#extra').val("false"); }
			     else { $('#extra').addClass('selected'); $('#extra').val("true"); }}
	else if (id == "sunday-school") { if (html == false) { $('#sunday-school').removeClass('selected'); $('#sunday-school').val("false"); }
			     else { $('#sunday-school').addClass('selected'); $('#sunday-school').val("true"); }}
	else if (id == "dues") { if (html == false) { $('#dues').removeClass('selected'); $('#dues').val("false"); }
			     else { $('#dues').addClass('selected'); $('#dues').val("true"); }}
	else if (id == "on-time") { if (html == false) { $('#on-time').removeClass('selected'); $('#on-time').val("false"); }
			     else { $('#on-time').addClass('selected'); $('#on-time').val("true"); }}
	else if (id == "club-level") {
	    switch (html) {
	    case "Cubbies": { $('#clubber-name-container').addClass('cubbies'); break; }
	    case "Sparks": { $('#clubber-name-container').addClass('sparks'); break; }
	    case "TnT": { $('#clubber-name-container').addClass('tnt'); break; }
	    case "Trek": { $('#clubber-name-container').addClass('trek'); break; }}}
	else if (id == "attendees-html") {
	    $('#attendees').html(html); }
        else if (id === 'notes') { $('#notes').val(html); }
	else { $('#' + id).text(html); }});
    if ($('#allergies').text() == "") { $('#allergy-container').css('display', 'none'); }
    else { $('#allergy-container').css('display', 'inline'); }
    $('#clubber-data').addClass('visible');
    $('#description-container').addClass('gone'); }

function stringToBoolean(s) {
    return s == "true" ? true : false; }

function setSaving(buttonId) {
    $('#' + buttonId).children('.attendance-saving-notifier')
        .attr('id', Math.floor(Math.random() * 100000000) + '').fadeIn(); }

function requestId(buttonId) {
    return $('#' + buttonId).children('.attendance-saving-notifier').attr('id'); }

function clearSaving(requestId) {
    $('#' + requestId).fadeOut(); }
