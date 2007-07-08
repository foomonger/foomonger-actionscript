/*
**********************************************************************************************
* www.foomonger.com
* Copyright 2007 Foomonger Development
*
* LoopEnterFrame.as
* Description:	Static class used to run loops over frames to spread out processing.
**********************************************************************************************

Examples:

import com.foomonger.utils.LoopEnterFrame;

// For Next
LoopEnterFrame.forNext(0, 100, 2, Delegate.create(this, doForNext));

function doForNext(i:Number):Boolean {
	trace(i);
	var result:Boolean = true;
	if (i == 24) {
		result = false;
	}
	return result;
}

// For Each
LoopEnterFrame.forEach(this, Delegate.create(this, doForIn));

function doForIn(name):Boolean {
	trace(name);
	return true;
}

// While True
LoopEnterFrame.whileTrue([20], Delegate.create(this, doWhileTrue));

var whileCounter:Number = 0;
function doWhileTrue(args:Array):Boolean {
	var max:Number = args[0];
	trace(whileCounter);
	whileCounter++;
	return (whileCounter < max);
}

*/

import mx.transitions.OnEnterFrameBeacon;

class com.foomonger.utils.LoopEnterFrame {

	// class data vars
		
	private static var __initBeacon = OnEnterFrameBeacon.init();		// using MM's enterFrame beacon
	private static var __loops:Array;									// holds loops to execute
	private static var __isConstructed:Boolean = false;	
	private static var __isEnterFrameRunning:Boolean = false;
	
	private static var FOR_NEXT:Number = 0;
	private static var FOR_EACH:Number = 1;
	private static var WHILE_TRUE:Number = 2;
	
	// --------------------------------------------------
	//	private functions
	// --------------------------------------------------

	/**
	 *	Initialized data. 
	 */
	private static function initialize():Void {
		if (!__isConstructed) {
			__isConstructed = true;
			__loops = new Array();
			OnEnterFrameBeacon.init();
		}
		if (!__isEnterFrameRunning) {
			__isEnterFrameRunning = true;
			_global.MovieClip.addListener(LoopEnterFrame);
		}
	}
	
	/**
	 *	Loops through the functions that use frames and execute them as neccessary.  Called by the enterFrame beacon.
	 */
	private static function onEnterFrame():Void {
		var i:Number;
		var obj:Object;
		
		i = 0;
		while (i < __loops.length) {
			obj = __loops[i];
			switch (obj.type) {
				case FOR_NEXT:
					executeForNext(obj, i);
					break;
				case FOR_EACH:
					executeForEach(obj, i);
					break;
				case WHILE_TRUE:
					executeWhileTrue(obj, i);
					break;
			}
			i++;
		}		
		
		if (__loops.length == 0) {
			__isEnterFrameRunning = false;
			_global.MovieClip.removeListener(LoopEnterFrame);
		}
	}
	
	/**
	 *	Executes the ForNext-style loop
	 */
	private static function executeForNext(obj:Object, i:Number):Void {
		var result:Boolean;
		
		if (obj.i < obj.end) {
			result = obj.func(obj.i);
			obj.i += obj.incr;
		} else {
			result = false;
		}
		
		if (!result) {
			__loops.splice(i, 1);
		}		
	}
	
	/**
	 *	Executes the ForEach-style loop
	 */
	private static function executeForEach(obj:Object, i:Number):Void {
		var result:Boolean;
		
		if (obj.i < obj.names.length) {
			result = obj.func(obj.names[obj.i]);
			obj.i++;
		} else {
			result = false;
		}
		
		if (!result) {
			__loops.splice(i, 1);
		}		
	}	

	/**
	 *	Executes the WhileTrue-style loop
	 */
	private static function executeWhileTrue(obj:Object, i:Number):Void {
		var result:Boolean;
		result = obj.func(obj.args);
		if (!result) {
			__loops.splice(i, 1);
		}		
	}	
	
	// --------------------------------------------------
	//	public functions
	// --------------------------------------------------
	
	/**
	 *	Executes a ForNext-style loop over frames.
	 *	@param 		start		The initial starting value of the counter. e.g. i = 0
	 *	@param 		end			The ending value of the counter. e.g. i < 100
	 *	@param		incr		The amount to increment the counter. e.g. i = i + 1
	 *	@param		func		The function to call on each frame of the loop.  It is passed the current counter.
	 */
	public static function forNext(start:Number, end:Number, incr:Number, func:Function):Void {
		initialize();
		
		var obj:Object = new Object();
		obj.type = FOR_NEXT;
		obj.i = start;
		obj.end = end;
		obj.incr = incr;
		obj.func = func;
		
		__loops.push(obj);
	}
	
	/**
	 *	Executes a ForEach-style loop over frames.
	 *	@param 		target		The object who's attributes to loop through.
	 *	@param		func		The function to call on each frame of the loop.  It is passed the current target's attribute name.
	 */
	public static function forEach(target:Object, func:Function):Void {
		initialize();
		
		var obj:Object = new Object();
		obj.type = FOR_EACH;
		obj.names = new Array();
		obj.target = target;
		obj.func = func;
		obj.i = 0;
		
		var name:String;
		for (name in target) {
			obj.names.push(name);
		}
				
		__loops.push(obj);
	}
	
	/**
	 *	Executes a WhileTrue-style loop over frames.
	 *	@param 		args		Array of arguments to pass to the function to run over frames.
	 *	@param		func		The function to call on each frame of the loop.  It is passed the given args.
	 */
	public static function whileTrue(args:Array, func:Function):Void {
		initialize();
		
		var obj:Object = new Object();
		obj.type = WHILE_TRUE;
		obj.args = args;
		obj.func = func;
				
		__loops.push(obj);
	}

}
