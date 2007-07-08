/*
**********************************************************************************************
* www.foomonger.com
* Copyright 2005 Foomonger Development
*
* DepthUtils.as
* Description:	My take on DepthManager.  Just one function for now.
**********************************************************************************************
*/

class com.foomonger.utils.DepthUtils {	 

	/**
	 *	Orders the depths of the given movie clips to match the order they are passed from lowest to highest.
	 *	Example Use:
	 		import com.foomonger.utils.DepthUtils;
			var box:MovieClip;
			var figure:MovieClip;
			var background:MovieClip;
			DepthUtils.orderDepths(background, figure, box);
	 */
	public static function orderDepths():Void {
		var i:Number;
		var j:Number;
		var ilen:Number;
		var jlen:Number;
		ilen = arguments.length;
		jlen = ilen;
		for (i = 0; i < ilen; i++) {
			for (j = (i + 1); j < jlen; j++) {
				if (arguments[i].getDepth() > arguments[j].getDepth()) {
					arguments[i].swapDepths(arguments[j]);
				}
			}
		}
	}
	
}