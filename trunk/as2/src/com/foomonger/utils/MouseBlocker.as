/*
**********************************************************************************************
* www.foomonger.com
* Copyright 2006 Foomonger Development
*
* MouseBlocker.as
* Description:	Simple little class that creates a box that blocks mouse events.
**********************************************************************************************

Example use:
	
	import com.foomonger.utils.MouseBlocker;
	var blocker:MouseBlocker = new MouseBlocker(this, "blocker", 100, 0xFF0000, 50, 0, 0, 800, 600);
	blocker.show();

*/

class com.foomonger.utils.MouseBlocker {
	
	private var __blocker:MovieClip;
	
	/**
	 *	Constructor:
	 *	Creates a MouseBlocker instance.
	 *	@param 		obj			MovieClip where to create the blocker.
	 *	@param 		name		Name of the blocker instance.
	 *	@param 		depth		Depth to create the blocker.
	 *	@param		rgb			Fill color.
	 *	@param		alphsa		Fill alpha.
	 *	@param		x			x coord to start the fill
	 *	@param		y			y coord to start the fill.
	 *	@param		width		Width of the fill.
	 *	@param		height		Height of the fill.
	 */
	function MouseBlocker(obj:MovieClip, name:String, depth:Number, rgb:Number, alpha:Number, x:Number, y:Number, width:Number, height:Number) {
		__blocker = obj.createEmptyMovieClip(name, depth);
		__blocker.beginFill(rgb, alpha);
		__blocker.moveTo(x, y);
		__blocker.lineTo(x + width, y);
		__blocker.lineTo(x + width, y + height);
		__blocker.lineTo(x, y + height);
		__blocker.lineTo(x, y);
		__blocker.endFill();		
		
		__blocker.onRelease = function() { return; };
		__blocker.useHandCursor = false;
		
		hide();
	}
	
	/**
	 *	Shows the blocker.
	 */
	public function show():Void {
		__blocker._visible = true;
	}

	/**
	 *	Hides the blocker.
	 */
	public function hide():Void {
		__blocker._visible = false;
	}
}