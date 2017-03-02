/**
* jQuery.scale plugin
* Copyright (c) 2009 to current, Oregon State Univerisity - info(at)osuosl.org | osuosl.org
* Dual-licensed under GPLv2 and the MIT License.
*
* @projectDescription jQuery extension for scaling an object to fit inside its parent while maintaining the aspect ratio
* @author Rob McGuire-Dale -  rob@osuoslcom
* @version 1.0
*
* @id jQuery.scale
* @id jQuery.fn.scale
* @param {String, [String]} In any order, enter "center" (to center the object) and/or "stretch" (to stretch the object to fit inside the parent) and/or "debug" (to turn on verbose logging)
* @return {jQuery} Returns the same jQuery object, for chaining.
*
* jQuery plugin structure based on "A Really Simple jQuery Plugin Tutorial" 
* (http://www.queness.com/post/112/a-really-simple-jquery-plugin-tutorial) by
* Kevin Liew
*/

(function($){                               // anonymous function wrapper

    $.fn.extend({                           // attach new method to jQuery
    
        scale: function( arg1, arg2, arg3 ){// declare plugin name and parameter
        
            // iterate over current set of matched elements
            return this.each( function()
            {
                // parse the arguments into flags
                var center = false,
                	stretch = false,
                	vert = false;
                if( arg1 == "center" || arg2 == "center" || arg3 == "center")
                    center = true;
                if( arg1 == "stretch" || arg2 == "stretch" || arg3 == "stretch")
                    stretch = true;
               	if( arg1 == "vert" || arg2 == "vert" || arg3 == "vert")
                    vert = true;
            
                // capture the object
                var obj = $(this);
                
                // if this is the plugin's first run on the object, and the
                // object is an image, force a reload
                if( obj.attr('src') && 
                    !obj.data('jquery_scale_orig-height') ){
                    
                    var date = new Date();
                    var cursrc = obj.attr("src");
                    var newsrc = "data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==";

                    obj.attr("src", newsrc);
			        obj.attr("src", cursrc);

                    obj.bind('load', scale);
                } else {
                    scale();
                }
                
                // plugin's main function
                function scale()
                {
                    // if this is the plugin's first run on the object, capture
                    // the object's original dimensions
                    if( !obj.data('jquery_scale_orig-height') ){
                        obj.data('jquery_scale_orig-height', obj.height() );
                        obj.data('jquery_scale_orig-width', obj.width() );
                        
                    
                    // if this is NOT the plugin's first run on the object,
                    // reset the object's dimensions
                    } else {           
                        obj.height( obj.data('jquery_scale_orig-height') );
                        obj.width( obj.data('jquery_scale_orig-width') );
                        
                    }

                    
                    // Object too tall, but width is fine. Need to shorten.
                    if( obj.outerHeight(  ) > obj.parent().innerHeight() && 
                        obj.outerWidth(  ) <= obj.parent().innerWidth() ){

                        matchHeight();       
                    }
                    
                    // Object too wide, but height is fine. Need to diet.
                    else if( obj.outerWidth(  ) > obj.parent().innerWidth() && 
                             obj.outerHeight(  ) <= obj.parent().innerHeight() ){

                        matchWidth();    
                    }
                    
                    // Object too short and skinny. If "stretch" option enabled,
                    // match the dimenstion that is closer to being correct.
                    else if( obj.outerWidth(  ) < obj.parent().innerWidth() && 
                             obj.outerHeight(  ) < obj.parent().innerHeight() &&
                             stretch ){
                      
                        if( obj.parent().innerHeight()/obj.outerHeight(  ) <= 
                            obj.parent().innerWidth()/obj.outerWidth(  ) ){
                            
                            matchHeight();
                            
                        } else {
                            matchWidth();
                        }
                    
                    // Object too tall and wide. Need to match the dimension 
                    // that is further from being correct.
                    } else if( obj.outerWidth(  ) > obj.parent().innerWidth() && 
                               obj.outerHeight(  ) > obj.parent().innerHeight() ){
                               
                        if( obj.parent().innerHeight()/obj.outerHeight(  ) >
                            obj.parent().innerWidth()/obj.outerWidth(  ) ){
                            
                            matchWidth();
                            
                        } else {
                            matchHeight();
                        }                            

                    }//else, object is the same size as the parent. Do nothing.

                    // if the center option is enabled, also center the object 
                    // within the parent
                    if( center ){
                        obj.css( 'position', 'relative' );
                        obj.css( 'margin-top', 
                             obj.parent().innerHeight()/2 - 
                                        obj.outerHeight(  )/2  );
                        obj.css( 'margin-left', 
                             obj.parent().innerWidth()/2 - 
                                        obj.outerWidth(  )/2  );
                    } else if (vert) {
                    	obj.css( 'margin-top', 
                             obj.parent().innerHeight()/2 - 
                                        obj.outerHeight(  )/2  );
                    }

                    // reset the onload pointer so the object doesn't flicker
                    // when reloaded other ways.
                     obj.unbind('load', scale);
         
                
                }   //END scale
                
                // match the height while maintaining the aspect ratio
                function matchHeight()
                {
                    obj.width( obj.outerWidth(  ) * 
                        obj.parent().innerHeight()/obj.outerHeight(  ) - 
                        (obj.outerWidth(  ) - obj.width()));
                    obj.height( obj.parent().innerHeight() - 
                        (obj.outerHeight(  ) - obj.height()) );
                }
                
                // match the width while maintaining the aspect ratio
                function matchWidth()
                {
                    obj.height(  obj.outerHeight(  ) * 
                        obj.parent().innerWidth()/obj.outerWidth(  ) - 
                        (obj.outerHeight(  ) - obj.height())  );
                    obj.width( obj.parent().width() - 
                        (obj.outerWidth(  ) - obj.width()));
                }
                            
            });     //END matched element iterations
        }           //END plugin declaration
    });             //END new jQuery method attachment
})(jQuery);         //END anonymous function wrapper
