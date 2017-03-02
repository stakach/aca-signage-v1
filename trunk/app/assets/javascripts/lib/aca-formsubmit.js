/**
*	ACA Common form control
*	All server communications are tunneled through these functions for consistency
*	
*   Copyright (c) 2011 Advanced Control and Acoustics.
*	
*	@author 	Stephen von Takach <steve@advancedcontrol.com.au>
* 	@copyright  2011 advancedcontrol.com.au
*	@version    1.0
**/


function common_response_error(xhr, status, error){
	var errors,
		errorText;
	
	try {
		// Populate errorText with the comment errors
		errors = $.parseJSON(xhr.responseText);
	} catch(err) {
		// If the responseText is not valid JSON (like if a 500 exception was thrown), populate errors with a generic error message.
		errors = {'Server error': 'Please reload the page and try again'};
	}
	
	// Build an unordered list from the list of errors
	errorText = 'There were issues with the submission: \n<ul>';
	for ( error in errors ) {
		errorText += '<li>' + error + ': ' + errors[error] + '</li> ';
	}
	errorText += '</ul>';
	
	// Display the error list
	$.noticeAdd({ text: errorText, stay: true });
}

$(document).ready(function() {
	$('form[data-remote]').live({
		
		//'ajax:beforeSend': function(evt, xhr, settings){},
		//'ajax:success': function(evt, data, status, xhr){},
		//'ajax:complete': function(evt, xhr, status){},
		
		'ajax:error': function (evt, xhr, status, error) {
			common_response_error(xhr, status, error);
		}
		
	});
});
