/*
**********************************************************************************************
* www.foomonger.com
* Copyright 2007 Foomonger Development
*
* LoadWatcher.as
* Description:	Watches the consolidated loading progress of the given objects.
**********************************************************************************************

Example (requires an images folder with jpgs):

import com.foomonger.utils.LoadWatcher;
import mx.utils.Delegate;
        
var loadWatcher:LoadWatcher = new LoadWatcher();
var images:Array = new Array();

loadWatcher.addEventListener(LoadWatcher.LOAD_PROGRESS, Delegate.create(this, onLoadProgress));
loadWatcher.addEventListener(LoadWatcher.LOAD_COMPLETE, Delegate.create(this, onLoadComplete));
loadWatcher.addEventListener(LoadWatcher.LOAD_COMPLETE_INIT, Delegate.create(this, onLoadCompleteInit));

for (var i = 1088; i < 1111; i++) {
	images.push(this.createEmptyMovieClip("image" + i.toString(), i));
	var mc:MovieClip = MovieClip(images[images.length - 1]);
	mc.loadMovie("images/CIMG" + i.toString() + ".JPG");
	mc._x = i - 1088 + 10;
	mc._y = mc._x;
}

loadWatcher.start.apply(loadWatcher, images);

function onLoadProgress(evt:Object):Void {
	var loaded:Number = evt.bytesLoaded;
	var total:Number = evt.bytesTotal;
	var percent:Number = Math.round(evt.percent * 100); 
	trace(loaded + "/" + total + " = " + percent);
}

function onLoadComplete(evt:Object):Void {
	trace("complete");
	trace("isTimedOut: " + evt.isTimedOut);
}

function onLoadCompleteInit(evt:Object):Void {
	trace("complete init");
}

*/

import mx.events.EventDispatcher;
import mx.transitions.OnEnterFrameBeacon;
import mx.utils.Delegate;

import com.foomonger.utils.Later;
 
class com.foomonger.utils.LoadWatcher {

	// --------------------------------------------------
	//	events
	// --------------------------------------------------
	
	/**
	 *	Dispatched on enterFrame during loading.
	 *	Returns an event object with the following properties:
	 *		bytesLoaded				Combined loaded bytes.
	 *		bytesTotals				Combined total bytes as available.
	 *		percentLoaded			Percentage (0 > 1) of the bytes loaded.
	 *		activePercentLoaded		Percentage (0 > 1) of the bytes loaded, taking into account the objects whose getBytesTotal() is a valid number > 0.
	 */
	public static var LOAD_PROGRESS:String = "loadProgress";
	/**
	 *	Dispatched when everything is loaded.
	 */
	public static var LOAD_COMPLETE:String = "loadComplete";
	/**
	 *	Dispatched 1 frame after everything is loaded.
	 */
	public static var LOAD_COMPLETE_INIT:String = "loadCompleteInit";
	
	private static var __initBeacon = OnEnterFrameBeacon.init();		// using MM's enterFrame beacon
	
	private var __content:Array;
	private var __lastTotals:Array;
	private var __lastOverallLoaded:Number;
	private var __timeout:Number = 30000;	// default 30 seconds
	private var __isTimeoutRunning:Boolean = false;
	private var __timeoutCaller:Object;
	
	function addEventListener() {}
	function removeEventListener() {}
	function dispatchEvent() {}

	function LoadWatcher() {
		EventDispatcher.initialize(this);
		__content = new Array();
		__lastTotals = new Array();
		OnEnterFrameBeacon.init();
	}
	
	// --------------------------------------------------
	//	public functions
	// --------------------------------------------------
	 
	/**
	 *	Watches the load on the given array of objects.  Pass any objects that have getBytesLoaded/getBytesTotal functions.
	 *	@param 		object1		Object to watch.
	 *	@param 		object2		
	 *	@param		objectN		
	 */
	public function start(object1, object2):Void {
		cleanContent(arguments);
		__lastOverallLoaded = 0;
		__isTimeoutRunning = false;
		startEnterFrame();
	}
	
	/**
	 *	Stops the watching.
	 */
	public function stop():Void {
		stopEnterFrame();
		
		// stop the timeout just in case it's running
		if (__isTimeoutRunning) {
			Later.abort(__timeoutCaller);
		}
	}
	
	private function startEnterFrame():Void {
		_global.MovieClip.addListener(this);
	}
	
	private function stopEnterFrame():Void {
		_global.MovieClip.removeListener(this);		
	}

	/**
	 *	Discards any objects that are undefined or do not have a getBytesLoaded() function.
	 */
	private function cleanContent(content:Array):Void {
		__content.splice(0);
		__lastTotals.splice(0);
		
		var badCount:Number = 0;
		var i:Number;
		var ilen:Number;
		ilen = content.length;
		for (i = 0; i < ilen; i++) {
			if ((content[i] != undefined)
					&& (content[i].getBytesLoaded != undefined)) {
				__content.push(content[i]);
				__lastTotals.push(0);
			} else {
				badCount++;
			}
		}
		
		if (__content.length > 0) {
			if (badCount > 0) {
				trace("**** WARNING **** LoadWatcher.start(): Found " + badCount.toString() + " bad objects.");
			}
		} else {
			trace("**** ERROR **** LoadWatcher.start(): Attempted to watch all bad content");
		}
		
	}

	/**
	 *	Calculates the load progress of the given objects.  Called by the enterFrame beacon.
	 */
	private function onEnterFrame():Void {
		var bytesTotal:Number = 0;
		var bytesLoaded:Number = 0;
		
		var partBytesTotal:Number = 0;
		var partBytesLoaded:Number = 0;
	
		var validObjects:Number = __content.length;

		var isValidTotal:Boolean = true;
		
		var i:Number;
		var ilen:Number;
		var part:Object;
		ilen = __content.length;
		
		for (i = 0; i < ilen; i++) {
			part = __content[i];
		
			partBytesLoaded = part.getBytesLoaded();
			if (isNaN(partBytesLoaded)) {
				partBytesLoaded = 0;
			}
			partBytesTotal = part.getBytesTotal();
			if (isNaN(partBytesTotal)) {
				partBytesTotal = 0;
			}				

			// total will be invalid if a part has 0 for total bytes
			if (partBytesTotal == 0) {
				isValidTotal = false;
				validObjects--;		// 1 less valid object
			}
			
			// total will be invalid if a part's total bytes changes
			if (__lastTotals[i] != partBytesTotal) {
				isValidTotal = false;
			}
			__lastTotals[i] = partBytesTotal;
			
			bytesTotal += partBytesTotal;
			bytesLoaded += partBytesLoaded;
		}
		
		var evt:Object = new Object();
		evt.type = LOAD_PROGRESS;
		evt.bytesLoaded = bytesLoaded;
		evt.bytesTotal = bytesTotal;
		evt.percent = ((validObjects / __content.length) * (bytesLoaded / bytesTotal));
		evt.percent = isNaN(evt.percent) ? 0 : evt.percent;
		
		dispatchEvent(evt);
		
		checkTimeout(bytesLoaded);

		if (isValidTotal) {
			if (bytesLoaded == bytesTotal) {
				dispatchEvent({type:LOAD_COMPLETE, isTimedOut:false});
				this.stop();
				Later.call(this, dispatchEvent, 1, false, {type:LOAD_COMPLETE_INIT});
			}
		}
	}
	
	/**
	 *	Checks and sets the timeout time if necessary.  The watching times out if the load progress is stuck for the timeout duration.
	 *	@param	bytesLoaded		The current bytes loaded.
	 */
	private function checkTimeout(bytesLoaded:Number):Void {
		// if bytes loaded hasn't changed
		if (__lastOverallLoaded == bytesLoaded) {
			// if timeout timer is running
			if (__isTimeoutRunning) {
				// do nothing
			} else {
				// set the timer
				__isTimeoutRunning = true;
				__timeoutCaller	= Later.call(this, callTimeout, __timeout, true);
			}
		// if bytes loaded has changed
		} else {
			if (__isTimeoutRunning) {
				// clear the timer
				__isTimeoutRunning = false;
				Later.abort(__timeoutCaller);
			}
		}
		__lastOverallLoaded = bytesLoaded;
	}

	/**
	 *	Stops the watching and sends the COMPLETE event with the isTimedOut flag set to true.
	 *	Called if the load progress is stuck for the timeout duration.
	 */
	private function callTimeout():Void {
		this.stop();	
		dispatchEvent({type:LOAD_COMPLETE, isTimedOut:true});
	}	
	

}