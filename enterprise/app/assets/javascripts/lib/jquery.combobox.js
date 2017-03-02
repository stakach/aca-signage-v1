(function( $ ) {
	$.widget( "ui.combobox", {
		options: {
			delay: 3,
			minLength: 0
		},
		_create: function() {
			var input,
				userSelect,
				self = this,
				select = this.element.hide(),
				selected = select.children( "option" ),
				value = selected.val() ? selected.text() : "",
				thechange = function( event, ui ) {
					if ( !ui.item ) {
						var name = selected.text();
						$( this ).val( name );
						select.val( name );
						input.data( "autocomplete" ).term = name;
						return false;
					}
				},
				wrapper = this.wrapper = $( "<span>" )
					.addClass( "ui-combobox" )
					.insertAfter( select );
				
			self.options['change'] = thechange;
			userSelect = self.options['select'];
			self.options['select'] = function(event, ui){
				selected.attr('value', ui.item.value).text(ui.item.label);
				
				if(!!userSelect)
					userSelect.apply(select, [event, ui]);
				
				$( this ).val( ui.item.label );
				select.val( ui.item.label );
				input.data( "autocomplete" ).term = ui.item.label;
				return false;
			};

			input = $( "<input>" )
				.appendTo( wrapper )
				.val( value )
				.addClass( "ui-state-default ui-combobox-input" )
				.autocomplete(self.options)
				.addClass( "ui-widget ui-widget-content ui-corner-left" );

			input.data( "autocomplete" )._renderItem = function( ul, item ) {
				return $( "<li></li>" )
					.data( "item.autocomplete", item )
					.append( "<a>" + item.label + "</a>" )
					.appendTo( ul );
			};

			$( "<a>" )
				.attr( "tabIndex", -1 )
				.attr( "title", "Show All Items" )
				.appendTo( wrapper )
				.button({
					icons: {
						primary: "ui-icon-triangle-1-s"
					},
					text: false
				})
				.removeClass( "ui-corner-all" )
				.addClass( "ui-corner-right ui-combobox-toggle" )
				.click(function() {
					// close if already visible
					if ( input.autocomplete( "widget" ).is( ":visible" ) ) {
						input.autocomplete( "close" );
						return;
					}

					// work around a bug (likely same cause as #5265)
					$( this ).blur();

					// pass empty string as value to search for, displaying all results
					input.autocomplete( "search", "" );
					input.focus();
				});
		},

		destroy: function() {
			this.wrapper.remove();
			this.element.show();
			$.Widget.prototype.destroy.call( this );
		}
	});
})( jQuery );