/**
*	jQuery.standardMenu()
*	These functions create hooks for a right click menu with common functions (delete, edit, retry)
*	Relies on: jquery.contextmenu.r2	// TODO:: refactor this library one day
*	
*   Copyright (c) 2011 Advanced Control and Acoustics.
*	
*	@author 	Stephen von Takach <steve@advancedcontrol.com.au>
* 	@copyright  2011 advancedcontrol.com.au
*	@version    1.0
**/

(function($) {
	
	$.widget( 'aca.standardMenu', {
		
		options: {
			menuElements: '*',
			menuHotspots: '*',
			menuBindings: {
				//'delete': function (t) {
				//	doDelete();
				//}
			},
			beforeShow: function(element) {},
			onShow: function(element, menu) {}
		},
		
		_init: function() {
			var $this = this,
				options = this.options;
			
			$this.element.find(options.menuHotspots).live('mouseover', function () {
				var $current = $(this);
		
				if (!!!$current.data('aca-menu')) {
					$current.data('aca-menu', true);
					$current.contextMenu('objectMenu', {
						bindings: options.menuBindings,
						itemStyle: {
							fontSize: '85%'
						},
						onContextMenu: function(e) {
							return options.beforeShow($(e.target).parents(options.menuElements));
						},
						onShowMenu: function(e, menu) {
							return options.onShow($(e.target).parents(options.menuElements), menu);
						}
					});
				}
			});
		}
		
	});
	
})(jQuery);