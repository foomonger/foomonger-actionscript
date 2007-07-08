/*
**********************************************************************************************
* www.foomonger.com
* Copyright 2007 Foomonger Development
*
* Later.as
* Description:	Static class used to call functions after a given amount of time.
**********************************************************************************************

Normal use:
	import com.foomonger.utils.Later;
	
	function foo(bar:String):Void {
		trace("foo = " + bar);
	}
	Later.exec(this, foo, 12, false, 0, "hello 12 frames later");
	Later.exec(this, foo, 2000, true, 0, "hello 2000 milliseconds later");

Simplest use:
	import com.foomonger.utils.Later;
	
	function foobar():Void {
		trace("foobar");
	}
	
	Later.exec(this, foobar);	// runs foobar 1 frame later

Property setting use:
	import com.foomonger.utils.Later;
	
	function traceBar():Void {
		trace("bar: " + bar);
	}

	var bar:Number = 100;
	trace("bar: " + bar);						// outputs "bar: 100"
	Later.set(this, "bar", 50, 5, false, 0);	// sets this.bar to 50 after 5 frames
	Later.exec(this, traceBar, 10, false, 0);	// outputs "bar: 50"
	
To immediately call all functions sent to Later.exec() do this:
	Later.finishAll();

To immediately abort all functions sent to Later.exec() do this:
	Later.abortAll();

You can also control individual calls to Later.exec() by saving the returned object:
	var laterObj:Object = Later.exec(this, foo, 12, false, 0, "hello 12 frames later");
	
You can then pass the object to the following functions:
	Later.abort(laterObj);
	Later.finish(later.Obj);
	
You can abort and finish Later calls by groups.
	The 5th argument is a number that assigns a group to the Later object.
	Use Later.getUniqueGroup() to ensure unique group numbers.

	var myGroup:Number = Later.getUniqueGroup();
	Later.exec(this, foo, 12, false, myGroup, "hello world");
	Later.exec(this, foo, 13, false, myGroup, "hello world");
	Later.exec(this, foo, 14, false, 0, "hello moon");
	Later.abortGroup(myGroup);
	
	This traces out only "hello moon".
*/

import mx.transitions.OnEnterFrameBeacon;
import mx.utils.Delegate;

class com.foomonger.utils.Later {
	
	// class data vars
	
	private static var __initBeacon = OnEnterFrameBeacon.init();		// using MM's enterFrame beacon
	private static var __secondsData:Object;							// associative array to keep track of functions that use seconds
	private static var __framesData:Array;								// array to keep track of functions that use frames
	private static var __isConstructed:Boolean = false;	
	private static var __isEnterFrameRunning:Boolean = false;
	private static var __groupCounter:Number = 1;						// counter of group numbers; 0 reserved for default
	
	// --------------------------------------------------
	//	private functions
	// --------------------------------------------------
	
	/**
	 *	Initialized data.  Run only the first time exec() is called.
	 */
	private static function initialize():Void {
		if (!__isConstructed) {
			__isConstructed = true;
			__secondsData = new Object();
			__framesData = new Array();
			OnEnterFrameBeacon.init();
		}
	}
	
	/**
	 *	Executes the later object function.
	 */
	private static function executeFunction(laterObj:Object):Void {
		var obj:Object = laterObj.obj;
		var func:Function = laterObj.func;
		var args:Array = laterObj.args;
		
		if (func != undefined) {
			func.apply(obj, args);
		}
	}
	
	/**
	 *	Clears the later object that uses seconds.
	 */
	private static function clearSecondsFunction(laterObj:Object):Void {
		clearInterval(laterObj.intervalId);
		var key:String = "id" + laterObj.intervalId.toString();
		delete __secondsData[key];
	}

	/**
	 *	Clears the later object that uses frames.
	 */
	private static function clearFramesFunction(laterObj:Object):Void {
		laterObj.duration = 0;
		laterObj.func = undefined;
	}
	
	/**
	 *	Runs the given later object function and clears it.  Called by setInterval in exec() for functions that use seconds.
	 */
	private static function onInterval(laterObj:Object):Void {
		executeFunction(laterObj);
		clearSecondsFunction(laterObj);
	}
	
	/**
	 *	Loops through the functions that use frames and execute them as neccessary.  Called by the enterFrame beacon.
	 */
	private static function onEnterFrame():Void {
		var i:Number;
		var ilen:Number;
		var laterObj:Object;

		i = 0;
		while (i < __framesData.length) {
			laterObj = __framesData[i];
			
			if (laterObj.duration > 1) {
				laterObj.duration--;
				i++;
			} else {
				executeFunction(laterObj);
				__framesData.splice(i, 1);
			}
		}		
		
		if (__framesData.length == 0) {
			__isEnterFrameRunning = false;
			_global.MovieClip.removeListener(Later);
		}
	}

	/**
	 *	Used by Later.set to set the property of an object.
	 *	@param 		obj			Object where the property lives.
	 *	@param 		prop		Property to set.
	 *	@param		value		Value to set the property too.
	 */
	private static function setObjectProperty(obj:Object, prop:String, value:Object):Void {
		obj[prop] = value;
	}
	
	// --------------------------------------------------
	//	public functions
	// --------------------------------------------------
	
	/**
	 *	Main Later class function.  Executes the given function after a given amount of time.  Arguments can also be passed.
	 *	@param 		obj			Object where the function lives.
	 *	@param 		func		Function to call.
	 *	@param		duration	Number of frames or milliseconds after which to call the given function.
	 *	@param		useSeconds	true = seconds, false = frames
	 *	@param		group		Group number to assign to the call.  Default = 0.
	 *	@param		...rest		Array of arguments to pass to the given function.
	 *	@returns	laterObj	An object that represents the given function.  Can be saved and passed to finish() and abort()
	 */
	public static function exec(obj:Object, func:Function, duration:Number, useSeconds:Boolean, group:Number):Object {
		initialize();

		duration = (duration == undefined) ? 1 : duration;
		duration = Math.max(duration, 1);
		useSeconds = (useSeconds == undefined) ? false : useSeconds;
		group = (group == undefined) ? 0 : group;
		var args:Array = arguments.slice(5);
		
		var laterObj:Object = new Object();
		laterObj.useSeconds = useSeconds;
		laterObj.obj = obj;
		laterObj.func = func;
		laterObj.group = group;
		laterObj.args = args;
		
		if (useSeconds) {
			laterObj.intervalId  = setInterval(Later.onInterval, duration, laterObj);
			var key:String = "id" + laterObj.intervalId.toString();
			__secondsData[key] = laterObj;
		} else {
			if (!__isEnterFrameRunning) {
				__isEnterFrameRunning = true;
				_global.MovieClip.addListener(Later);
			}
			laterObj.duration = duration;
			__framesData.push(laterObj);
		}
		
		return laterObj;
	}
	
	/**
	 *	Set the given property with the given value after a given amount of time.
	 *	@param 		obj			Object where the property lives.
	 *	@param 		prop		Property to set.
	 *	@param		value		Value to set the property too.
	 *	@param		duration	Number of frames or milliseconds after which to call the given function.
	 *	@param		useSeconds	true = seconds, false = frames
	 *	@param		group		Group number to assign to the call.  Default = 0.
	 *	@returns	laterObj	An object that represents the given function.  Can be saved and passed to finish() and abort()
	 */
	public static function set(obj:Object, prop:String, value:Object, duration:Number, useSeconds:Boolean, group:Number):Object {
		return Later.exec(Later, Later.setObjectProperty, duration, useSeconds, group, obj, prop, value);
	}

	
	/**
	 *	Immediately call the given later object.
	 *	@param	laterObj	An object representing a function sent to exec().
	 */
	public static function finish(laterObj:Object):Void {
		// if finish's caller was called Later.exec
		if (arguments.caller == laterObj.func) {
			// avoid recursion, no need to do anything
		} else {
			executeFunction(laterObj);
			abort(laterObj);			
		}

	}

	/**
	 *	Immediately calls all functions sent to exec().
	 */
	public static function finishAll():Void {
		var laterObj:Object;

		// seconds
		var name:String;
		for (name in __secondsData) {
			laterObj = __secondsData[name];
			// if finishAll's caller was called Later.exec
			if (arguments.caller == laterObj.func) {
				// avoid recursion and just abort
				abort(laterObj);
			} else {
				// finish
				finish(laterObj);
			}
		}

		// frames
		var i:Number;
		var ilen:Number = __framesData.length;
		for (i = 0; i < ilen; i++) {
			laterObj = __framesData[i];
			// if finish's caller was called Later.exec
			if (arguments.caller == laterObj.func) {
				// avoid recursion and just abort
				abort(laterObj);
			} else {
				// finish
				finish(laterObj);
			}
		}
	}
	
	/**
	 *	Immediately calls all functions sent to exec() in the given group.
	 *	@param	group		The number of the group to finish.
	 *	@param	caller		Pass arguments.callee from the calling function to prevent recursion.
	 */
	public static function finishGroup(group:Number):Void {
		var laterObj:Object;

		// seconds
		var name:String;
		for (name in __secondsData) {
			laterObj = __secondsData[name];
			if (arguments.caller == laterObj.func) {
				abort(laterObj);
			} else {
				if (laterObj.group == group) {
					finish(laterObj);
				}
			}
		}

		// frames
		var i:Number;
		var ilen:Number = __framesData.length;
		for (i = 0; i < ilen; i++) {
			laterObj = __framesData[i];
			if (arguments.caller == laterObj.func) {
				abort(laterObj);
			} else {
				if (laterObj.group == group) {
					finish(laterObj);
				}
			}
		}
	}
	
	/**
	 *	Aborts the given later object.
	 *	@param	laterObj	An object representing a function sent to exec().
	 */
	public static function abort(laterObj:Object):Void {
		if (laterObj.useSeconds) {
			clearSecondsFunction(laterObj);
		} else {
			clearFramesFunction(laterObj);
		}
	}
	
	/**
	 *	Immediately aborts all functions sent to exec().
	 */
	public static function abortAll():Void {		
		var laterObj:Object;

		// seconds
		var name:String;
		for (name in __secondsData) {
			laterObj = __secondsData[name];
			abort(laterObj);
		}
		
		// frames
		__framesData.splice(0);	// dont need to loop and abort individually
	}
	
	
	/**
	 *	Immediately aborts all functions sent to exec() in the given group.
	 *	@param	group		The number of the group to abort.
	 */
	public static function abortGroup(group:Number):Void {		
		var laterObj:Object;

		// seconds
		var name:String;
		for (name in __secondsData) {
			laterObj = __secondsData[name];
			if (laterObj.group == group) {
				abort(laterObj);
			}
		}

		// frames
		var i:Number;
		var ilen:Number = __framesData.length;
		for (i = 0; i < ilen; i++) {
			laterObj = __framesData[i];
			if (laterObj.group == group) {
				abort(laterObj);
			}
		}
	}
	
	/**
	 *	Returns a unique group number.
	 */
	public static function getUniqueGroup():Number {
		return __groupCounter++;
	}

}