/*
**********************************************************************************************
* www.foomonger.com
* Copyright 2007 Foomonger Development
*
* LoadWatcher.as
* Description:	Watches the consolidated loading progress of the given objects.
**********************************************************************************************

Example:

import com.foomonger.utils.LoadWatcher;
import mx.utils.Delegate;
	
var loadWatcher:LoadWatcher = new LoadWatcher();
var my_mc:MovieClip;
var my_xml:XML;

loadWatcher.addEventListener(LoadWatcher.LOAD_PROGRESS, Delegate.create(this, onLoadProgress));
loadWatcher.addEventListener(LoadWatcher.LOAD_COMPLETE, Delegate.create(this, onLoadComplete));
loadWatcher.addEventListener(LoadWatcher.LOAD_COMPLETE_INIT, Delegate.create(this, onLoadCompleteInit));
my_mc.createEmptyMovieClip("my_mc", 0);
my_xml = new XML();
my_mc.loadMovie("path/to/file.swf");
my_xml.load("path/to/file.xml");
loadWatcher.start(my_mc, my_xml);

function onLoadProgress(evt:Object):Void {
	var loaded:Number = evt.loadedBytes;
	var total:Number = evt.loadedBytes;
	var percent:Number = Math.round(evt.percentLoaded * 100); 
	var activePercent:Number = Math.round(evt.activePercentLoaded * 100); 
	trace(loaded + "/" + total + " = " + percent + "\t" + activePercent);
}
function onLoadComplete(evt:Object):Void {
	trace("complete");
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
	 *		loadedBytes				Combined loaded bytes.
	 *		totalBytess				Combined total bytes as available.
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
		startEnterFrame();
	}
	
	/**
	 *	Stops the watching.
	 */
	public function stop():Void {
		stopEnterFrame();
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
		var totalBytes:Number = 0;
		var loadedBytes:Number = 0;
		
		var partTotalBytes:Number = 0;
		var partLoadedBytes:Number = 0;
	
		var validObjects:Number = __content.length;

		var isValidTotal:Boolean = true;
		
		var i:Number;
		var ilen:Number;
		var part:Object;
		ilen = __content.length;
		
		for (i = 0; i < ilen; i++) {
			part = __content[i];
		
			if (part.getBytesTotal == undefined) {
				trace("**** WARNING **** LoadWatcher.doWatch():  Content " + i + " has become invalid.");
				partTotalBytes = 0;
				partLoadedBytes = 0;
			} else {
				partLoadedBytes = part.getBytesLoaded();
				if (isNaN(partLoadedBytes)) {
					partLoadedBytes = 0;
				}
				partTotalBytes = part.getBytesTotal();
				if (isNaN(partTotalBytes)) {
					partTotalBytes = 0;
				}				
			}

			// total will be invalid if a part has 0 for total bytes
			if (partTotalBytes == 0) {
				isValidTotal = false;
				validObjects--;		// 1 less valid object
			}
			
			// total will be invalid if a part's total bytes changes
			if (__lastTotals[i] != partTotalBytes) {
				isValidTotal = false;
			}
			__lastTotals[i] = partTotalBytes;
			
			totalBytes += partTotalBytes;
			loadedBytes += partLoadedBytes;
		}
		
		var evt:Object = new Object();
		evt.type = LOAD_PROGRESS;
		evt.loadedBytes = loadedBytes;
		evt.totalBytes = totalBytes;
		evt.percentLoaded = (loadedBytes / totalBytes);
		evt.activePercentLoaded = ((validObjects / __content.length) * (loadedBytes / totalBytes));
		evt.percentLoaded = isNaN(evt.percentLoaded) ? 0 : evt.percentLoaded;
		evt.activePercentLoaded = isNaN(evt.activePercentLoaded) ? 0 : evt.activePercentLoaded;
		
		dispatchEvent(evt);

		if (isValidTotal) {
			if (loadedBytes >= totalBytes) {
				dispatchEvent({type:LOAD_COMPLETE});
				_global.MovieClip.removeListener(this);
				stopEnterFrame();
				Later.exec(this, dispatchEvent, 1, false, 0, {type:LOAD_COMPLETE_INIT});
			}
		}
	}
	

}