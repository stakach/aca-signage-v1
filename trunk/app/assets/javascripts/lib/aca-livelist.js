/**
*	jQuery.liveList()
*	These functions create hooks for an interactive table list
*	
*   Copyright (c) 2011 Advanced Control and Acoustics.
*	
*	@author 	Stephen von Takach <steve@advancedcontrol.com.au>
* 	@copyright  2011 advancedcontrol.com.au
*	@version    1.0
**/

(function($) {
	$.widget( 'aca.liveList', {
		options: {
			searchFormSelector: null, 			// Search form for ajax hooks
			searchLoadData: function ($form, page, orderBy, orderType) { },
			searchPageLength: 50,
			scrollingContainer: null,			// Container we are checking for pagination (if null then parent is assumed)

			selectableObject: 'tbody tr',
			selectedClass: 'selected',			// Selected items class (for alt styling)
			selectionSelectable: function($item) {
				return true;
			},
			selectionChange: function ($selected) { },// Selection has changed (for updating a preview pane)
			deselectionAreas: null,
			
			dragOptions: {},			// See jQuery Draggable documentation
			dragHandle: null,

			sortableObject: 'thead th.orderable',
			sortableActive: 'ordered',	// Currently sorted column
			sortedDescending: 'desc',	// Sorted desc or asc
			sortedAscending: 'asc'
		},

		currentOffset: 0,
		searching: false,
		
		_init: function() {
			var options = this.options,
				$this = this;
			
			
			//
			// List selection code ---------------------------------
			//
			this.element.find(options.selectableObject).live('click', function(event) {
				var $current = $(this);
	
				//
				// Check this item can be selected
				//
				if (!options.selectionSelectable($current))
					return;
	
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					if (event.altKey || event.originalEvent.altKey || event.shiftKey) {
	
						//
						// ALT or SHIFT key as the group selection modifier
						//
						var allSelected = $this.element.find(options.selectableObject + '.' + options.selectedClass);
						var length = allSelected.length;
						var element = allSelected[length - 1];	// Last element in the selected list
	
						if (length > 0 && $current[0] != element)
						{
							var found = false;
	
							//
							// Run through the list looking for the selected object
							//
							$this.element.find(options.selectableObject).each(function(i) {
								if (!options.selectionSelectable($(this)))
									return;
								if (found) {
									$(this).addClass(options.selectedClass);
								}
								if (this == $current[0] || this == element) {	// Have we found the last item in the list or the clicked item
									found = !found;
									$(this).addClass(options.selectedClass);
								}
							});
						}
						else {
							//
							// CTRL+ALT with nothing previously selected, act like CTRL key only
							//
							$current.addClass(options.selectedClass);
						}
					}
					else {
						//
						// CTRL key only (meta-key for apple computers)
						//
						$current.toggleClass(options.selectedClass);
					}
				}
				else {
					//
					// Click with no modifier keys selected
					//
					$this.element.find(options.selectableObject + '.' + options.selectedClass).removeClass(options.selectedClass);
					$current.addClass(options.selectedClass);
				}
	
				//
				// Update preview
				//
				options.selectionChange($this.element.find(options.selectableObject + '.' + options.selectedClass));
			});
	
			//
			// deselection code
			//
			if(options.deselectionAreas != null) {
				$(options.deselectionAreas).click(function(event) {
					if (event.target != $(this)[0])
						return;
	
					var $list = $this.element.find(options.selectableObject + '.' + options.selectedClass);
	
					if($list.length > 0 && !(event.ctrlKey || event.metaKey)) {
						$list.removeClass(options.selectedClass);
						options.selectionChange($this.element.find(options.selectableObject + '.' + options.selectedClass));
					}
				});
			}
			
			
			//
			// Draggable object code ----------------------------------
			//
			var defaultDrag = $.extend({
				revert: 'invalid',	// Don't revert after a successful drop
				helper: function () {	// Create a nice looking drag object
	
					//
					// Make sure this object is selected
					//
					if(options.dragHandle == null)
						$this.checkSelection($(this));
					else
						$this.checkSelection($(this).parents(options.selectableObject));
	
					//
					// TODO:: unselect any selectable list items that cannot be dragged.
					//	Cancel drag if nothing selected (probably should be done in start?)
					//	Does not effect iMedTV
					//
					
					return $('<div id="multi-copy"><div id="multi-copy-star">' + $this.element.find(options.selectableObject + '.' + options.selectedClass).length + '</div></div>');
				},
				scroll: false,
				cursor: 'default',
				cursorAt: {
					left: -5,
					top: -5
				}
			}, options.dragOptions);
	
			//
			// Find the objects that will actually be draggable
			//
			var objects = null;
			if(options.dragHandle == null)
				objects = this.element.find(options.selectableObject);
			else
				objects = this.element.find(options.dragHandle);
	
			//
			// By setting the drag on mouseover we ensure the elements are always draggable
			//	TODO:: Check there isn't a better way to do this
			//
			objects.live('mouseover', function() {
				var $current = $(this);
	
				if (!!!$current.data('aca-list')) {
					$current.data('aca-list', true);
					$current.draggable(defaultDrag);
					$current.disableSelection();
				}
			});
			
			
			//
			// Searching hooks -----------------------------------------
			//	searchLoadData: function ($form, data page, orderBy, orderType, searchCompleteFunc) { },
			//
			
			//
			// Search form submit
			//
			$(options.searchFormSelector).submit(function() {
				if(!$this.searching)
					$this.doSearch(0);	// Brand new search
	
				return false;	// Prevent page reload
			});
	
			//
			// Column sort change
			//
			this.element.find(options.sortableObject).live('click', function() {
				if($this.searching)
					return;
	
				var ordered = $this.element.find(options.sortableObject + '.' + options.sortableActive),
				    $current = $(this);
	
				if($current.hasClass(options.sortableActive)){
					if(ordered.hasClass(options.sortedDescending)) {
						ordered.removeClass(options.sortedDescending).addClass(options.sortedAscending);
					} else {
						ordered.removeClass(options.sortedAscending).addClass(options.sortedDescending);
					}
				} else {
					ordered.removeClass(options.sortableActive).removeClass(options.sortedAscending).removeClass(options.sortedDescending);
					$current.addClass(options.sortableActive).addClass(options.sortedDescending);
				}
				
				$this.doSearch(0);	// Brand new search
			});
			
			this.doSearch(0);
			this.element.disableSelection();
		},
		
		
		checkSelection: function(someObject) {
			var selection = $(someObject),
				options = this.options;

			//
			// If we are dragging an unselected object unselect the other objects
			//
			if (!selection.hasClass(options.selectedClass))
				this.element.find(options.selectableObject + '.' + options.selectedClass).removeClass(options.selectedClass);
			
			selection.addClass(options.selectedClass);

			//
			// Update preview
			//
			options.selectionChange(this.element.find(options.selectableObject + '.' + options.selectedClass));
		},
		
		

		//
		// Searching hooks -----------------------------------------
		//	searchLoadData: function ($form, data page, orderBy, orderType, searchCompleteFunc) { },
		//
		doSearch: function(offset) {
			if(this.searching)
				return;
				
			var options = this.options;
			
			var $form = $(options.searchFormSelector),
			    sortableCol = this.element.find(options.sortableObject + '.' + options.sortableActive);
			var orderBy = sortableCol.data('dbcol'),
			    orderType;

			if(sortableCol.hasClass(options.sortedAscending))
				orderType = options.sortedAscending;
			else if(sortableCol.hasClass(options.sortedDescending))
				orderType = options.sortedDescending;
			else
				orderType = options.sortedDescending;

			this.searching = true;
			this.currentOffset = offset;
			
			options.searchLoadData($form, offset, orderBy, orderType);

			//if(page == 0)
			//	options.selectionChange(this.element.find(options.selectableObject + '.' + options.selectedClass));
		},

		searchComplete: function() {
			this.searching = false;
			var options = this.options;
			if(this.currentOffset == 0)
				options.selectionChange(this.element.find(options.selectableObject + '.' + options.selectedClass));

			this.paginateScrolling();	// Check if more data needs to be loaded or a hook put in place
			
			//options.selectionChange(this.element.find(options.selectableObject + '.' + options.selectedClass));
		},

		

		//
		// Paginated scrolling -----------------------------------------------
		//
		paginateScrolling: function() {
			if(this.searching)
				return;

			var options = this.options,
				$container,
				offset,
				$this = this;

			if(options.scrollingContainer == null)
				$container = this.element.parent();
			else
				$container = $(options.scrollingContainer);
			
			if($container[0].clientHeight >= $container[0].scrollHeight || $container.scrollTop() >= this.element.height() - $container.height() - 50) {	// 50 == buffer before we start paginating
				offset = this.element.find(options.selectableObject).length;
				//
				// TODO:: Deleting exactly 1 page of items will invalidate this logic. Minor issue?
				//	Can be fixed by checking if the current list length is different to a cached value
				//
				if(offset != this.currentOffset)
					this.doSearch(offset);
			}
			else {
				$container.scroll(function(){
					if  ($container.scrollTop() >= $this.element.height() - $container.height() - 50){
						$container.unbind('scroll');
						offset = $this.element.find(options.selectableObject).length;
						if(offset != $this.currentOffset)
							$this.doSearch(offset);
					}
				});
			}
		}
	});
})(jQuery);