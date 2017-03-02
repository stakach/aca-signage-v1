

var Effect = (function($, global) {
	var container,
		wrapper,
		all,
		next,
		current,
		finished,
		transition,
		transitions = [
			[null, startFadeToBlack, null, null, null, null],	// fade to black
			[null, doInstantTransistion, null, null, null, null],	// instant
			
			[null, transition2D, complete2D, 'crossfade', null, null],	// cross fade
			[null, transition2D, complete2D, 'explode', null, null],
			
			[prepare2D, transition2D, complete2D, 'push top', null, cancel2D_transition],		// push_from_top	(slide)
			[prepare2D, transition2D, complete2D, 'push bottom', null, cancel2D_transition],	// push_from_bottom
			[prepare2D, transition2D, complete2D, 'push left', null, cancel2D_transition],	// push_from_left
			[prepare2D, transition2D, complete2D, 'push right', null, cancel2D_transition],	// push_from_right
			
			[null, transition2D, complete2D, 'slide-out top', null, null],						// slide_top_out (uncover)
			[prepare2D, transition2D, complete2D, 'slide-in top', null, cancel2D_transition],	// slide_top_in
			[null, transition2D, complete2D, 'slide-out bottom', null, null],					// slide_bottom_out
			[prepare2D, transition2D, complete2D, 'slide-in bottom', null, cancel2D_transition],	// slide_bottom_in
			[null, transition2D, complete2D, 'slide-out left', null, null],						// slide_left_out
			[prepare2D, transition2D, complete2D, 'slide-in left', null, cancel2D_transition],	// slide_left_in
			[null, transition2D, complete2D, 'slide-out right', null, null],						// slide_right_out
			[prepare2D, transition2D, complete2D, 'slide-in right', null, cancel2D_transition],	// slide_right_in
			
			[null, transition2D, complete2D, 'spin-out', null, null],		// spin_out
			[prepare2D, transition2D, complete2D, 'spin-in', null, cancel2D_transition],			// spin_in
			[null, transition2D, complete2D, 'flyout', null, null],		// flyout
			[prepare2D, transition2D, complete2D, 'flyin', null, cancel2D_transition],				// flyin
			
			[prepare2D, transition2D, complete2D, 'iris', null, cancel2D_transition],
			
			[null, transition3D, complete3D, 'flip-hori', 'flipped', null],	// flip_hori
			[null, transition3D, complete3D, 'flip-vert', 'flipped', null]	// flip_vert
			
			
			//
			// TODO:: 3D cube (may require ready state) -- prepare
			//
		];
	
	
	global.transitioning = false;
	
	
	function startFadeToBlack(){
		$('#fader').hide().css('z-index', 10).fadeIn(800, function(){
			current.prependTo(wrapper);				// Swap positions
			$(this).fadeOut(800, function(){
				$(this).css('z-index', 0);
				global.transitioning = false;
				finished();							// The call back - item is played here
			});
		});
	}
	
	
	function doInstantTransistion(){
		
		current.prependTo(wrapper);				// Swap positions
		
		setTimeout(function(){
			global.transitioning = false;
			finished();
		}, 0);
		
	}
	
	
	//
	// 3D Common Transition code
	//
	function transition3D(type, trigger) {
		current.addClass('out');				// in out
		next.addClass('in');
		wrapper.addClass(type);					// Add Local styles
		container.addClass('perspective');		// Add Global timings
		
		
		wrapper.addClass(trigger); 				// Apply transition
	}
	
	function complete3D(type, trigger) {
		//current.css('display', 'none');			// hide
		container.removeClass('perspective');	// remove global timings
		wrapper.removeClass(type);				// remove local styles
		wrapper.removeClass(trigger);			// remove animation trigger
		
		current.removeClass('out');				// remove in and out
		next.removeClass('in');
		
		current.prependTo(wrapper);				// Swap positions
	}
	
	
	
	
	
	//
	// 2D common transition code
	//
	function transition2D(type, trigger) {
		current.addClass('out');				// add in out
		next.addClass('in');
		
		all.addClass(type);						// Add Local styles			(Articles - children)
	}
	
	function complete2D(type, trigger) {
		if (transition[5] != null) {
			transition[5]();					// Undo any prepared transitions
		}
		
		all.removeClass(type);					// remove local styles
		
		current.removeClass('out');				// remove in and out
		next.removeClass('in');
		
		current.prependTo(wrapper);				// Swap positions
	}
	
	function prepare2D() {
		next.addClass('ready-' + transition[3]);
	}
	
	function cancel2D_transition() {
		next.removeClass('ready-' + transition[3]);
	}
	
	
	//
	// Wait for jQuery to load
	//
	$(function() {
		
		container = $('#container');
		wrapper = $('section');
		all = $('article');
		
		wrapper.bind('webkitTransitionEnd mozTransitionEnd msTransitionEnd oTransitionEnd transitionend', function(){
			if(!global.transitioning)
				return;
			
			transition[2].apply(transition, transition.slice(3));
			
			global.transitioning = false;
			finished();				// The call back - item is played here
		});
		
	});
	
	
	return function(cur, nxt, effect, callback) {
		if(global.transitioning)
			return;
		
		
		current = cur;
		next = nxt;
		if(effect < 2 || $.support.transitions)
			transition = transitions[effect];	// [container class, effect name, action class]
		else
			transition = transitions[0];
			
		finished = callback;
		
		
		if(!global.transitioning) {
			if (transition[0] != null) {
				transition[0]();			// Call the prepare function on load
			}
		}
		
		
		this.cancel = function() {
			if(global.transitioning)
				return;
			
			if (transition[5] != null) {
				transition[5]();			// Cancel any prepared transitions
			}
		};
		
		
		this.transition = function(){
			/*if(global.transitioning)
				return;*/
				
			global.transitioning = true;
			transition[1].apply(transition, transition.slice(3));
		};
	};
	
	
})(jQuery, this);

