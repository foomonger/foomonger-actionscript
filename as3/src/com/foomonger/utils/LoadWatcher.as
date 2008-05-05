/*
**********************************************************************************************
* www.foomonger.com
* Copyright 2007 Foomonger Development
*
* LoadWatcher.as
* Description:	Watches the consolidated loading progress of the given objects.
**********************************************************************************************

Example (requires an images folder with jpgs):

import com.foomonger.events.LoadWatcherEvent;
import com.foomonger.utils.LoadWatcher;

import flash.display.Loader;
import flash.net.URLRequest;

var loadWatcher:LoadWatcher = new LoadWatcher();
var images:Array = new Array();

loadWatcher.addEventListener(LoadWatcherEvent.PROGRESS, onLoadProgress);
loadWatcher.addEventListener(LoadWatcherEvent.COMPLETE, onLoadComplete);
loadWatcher.addEventListener(LoadWatcherEvent.COMPLETE_INIT, onLoadCompleteInit);

for (var i:uint = 1088; i < 1111; i++) {		
	var loader:Loader = new Loader();
	loader.load(new URLRequest("images/CIMG" + i.toString() + ".JPG"));
	loader.x = i - 1088 + (10 * (i - 1088));
	loader.y = loader.x;
	
	addChild(loader);
	images.push(loader.contentLoaderInfo);
}

loadWatcher.start.apply(loadWatcher, images);

function onLoadProgress(evt:LoadWatcherEvent):void {
	var loaded:uint = evt.bytesLoaded;
	var total:uint = evt.bytesTotal;
	var percent:Number = Math.round(evt.percent * 100); 
	trace(loaded + "/" + total + " = " + percent);
}

function onLoadComplete(evt:LoadWatcherEvent):void {
	trace("complete");
	trace("isTimedOut: " + evt.isTimedOut);
}

function onLoadCompleteInit(evt:LoadWatcherEvent):void {
	trace("complete init");
}

*/

package com.foomonger.utils {

	import com.foomonger.events.LoadWatcherEvent;
	import com.foomonger.utils.later.LaterOperation;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class LoadWatcher extends EventDispatcher {
	
		private static var _mc:MovieClip = new MovieClip();
		private var _content:Array;
		private var _lastTotals:Array;
		private var _lastOverallLoaded:uint;
		private var _timeout:uint = 30000;	// default 30 seconds
		private var _isTimeoutRunning:Boolean = false;
		private var _timeoutCaller:LaterOperation;
		private var _progressEvent:LoadWatcherEvent;
		private var _completeEvent:LoadWatcherEvent;
		private var _completeInitEvent:LoadWatcherEvent;
			
		public function LoadWatcher() {
			_content = new Array();
			_lastTotals = new Array();
			_progressEvent = new LoadWatcherEvent(LoadWatcherEvent.PROGRESS);
			_completeEvent = new LoadWatcherEvent(LoadWatcherEvent.COMPLETE);
			_completeInitEvent = new LoadWatcherEvent(LoadWatcherEvent.COMPLETE_INIT);

		}
		
		// --------------------------------------------------
		//	public functions
		// --------------------------------------------------
		 
		/**
		 *	Watches the load on the given objects.  Pass any objects that have bytesLoaded and bytesTotal properties.
		 *	@param 		args		Object to watch.
		 */
		public function start(... args):void {
			cleanContent(args);
			_lastOverallLoaded = 0;
			_isTimeoutRunning = false;
			startEnterFrame();
		}
		
		/**
		 *	Stops the watching.
		 */
		public function stop():void {
			stopEnterFrame();
			
			// stop the timeout just in case it's running
			if (_isTimeoutRunning) {
				Later.abortOperation(_timeoutCaller);
			}
		}
		
		/**
		 * Setter for timeout.
		 * @param	value	Timeout value in milliseconds.		 */
		public function set timeout(value:uint):void {
			_timeout = value;
		}
		
		/**
		 * Getter for timeout.
		 * @returns	uint	Current timeout value.
		 */
		public function get timeout():uint {
			return _timeout;
		}
		
		private function startEnterFrame():void {
			_mc.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
		}
		
		private function stopEnterFrame():void {
			_mc.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
	
		/**
		 *	Discards any objects that are undefined or do not have a getBytesLoaded() function.
		 */
		private function cleanContent(content:Array):void {
			_content.splice(0);
			_lastTotals.splice(0);
			
			var badCount:uint = 0;
			var i:uint;
			var ilen:uint;
			var temp:uint;
			ilen = content.length;
			for (i = 0; i < ilen; i++) {
				try {
					temp = content[i].bytesLoaded + content[i].bytesTotal;
					_content.push(content[i]);
					_lastTotals.push(0);
				} catch (err:Error) {
					badCount++;
				}
			}
			
			if (_content.length > 0) {
				if (badCount > 0) {
					trace("**** WARNING **** LoadWatcher.start(): Found " + badCount.toString() + " bad objects.");
				}
			} else {
				trace("**** ERROR **** LoadWatcher.start(): Attempted to watch all bad content");
			}
			
		}
	
		/**
		 *	Calculates the load progress of the given objects. 
		 */
		private function onEnterFrame(event:Event):void {
			var bytesTotal:uint = 0;
			var bytesLoaded:uint = 0;
			
			var partBytesTotal:uint = 0;
			var partBytesLoaded:uint = 0;
		
			var validObjects:uint = _content.length;
	
			var isValidTotal:Boolean = true;
			
			var i:uint;
			var ilen:uint;
			var part:Object;
			ilen = _content.length;
			
			for (i = 0; i < ilen; i++) {
				part = _content[i];
			
				partBytesLoaded = part.bytesLoaded;
				if (isNaN(partBytesLoaded)) {
					partBytesLoaded = 0;
				}
				partBytesTotal = part.bytesTotal;
				if (isNaN(partBytesTotal)) {
					partBytesTotal = 0;
				}	
				// total will be invalid if a part has 0 for total bytes
				if (partBytesTotal == 0) {
					isValidTotal = false;
					validObjects--;		// 1 less valid object
				}
				
				// total will be invalid if a part's total bytes changes
				if (_lastTotals[i] != partBytesTotal) {
					isValidTotal = false;
				}
				_lastTotals[i] = partBytesTotal;
				
				bytesTotal += partBytesTotal;
				bytesLoaded += partBytesLoaded;
			}
			
			_progressEvent.bytesLoaded = bytesLoaded;
			_progressEvent.bytesTotal = bytesTotal;
			_progressEvent.percent = ((validObjects / _content.length) * (bytesLoaded / bytesTotal));
			_progressEvent.percent = isNaN(_progressEvent.percent) ? 0 : _progressEvent.percent;
			
			dispatchEvent(_progressEvent);

			checkTimeout(bytesLoaded);
	
			if (isValidTotal) {
				if (bytesLoaded == bytesTotal) {
					_completeEvent.isTimedOut = false;
					dispatchEvent(_completeEvent);
					stop();
					Later.call(dispatchEvent, 1, false, _completeInitEvent);
				}
			}
		}
		
		/**
		 *	Checks and sets the timeout time if necessary.  The watching times out if the load progress is stuck for the timeout duration.
		 *	@param	bytesLoaded		The current bytes loaded.
		 */
		private function checkTimeout(bytesLoaded:uint):void {
			// if bytes loaded hasn't changed
			if (_lastOverallLoaded == bytesLoaded) {
				// if timeout timer is running
				if (_isTimeoutRunning) {
					// do nothing
				} else {
					// set the timer
					_isTimeoutRunning = true;
					_timeoutCaller	= Later.call(callTimeout, _timeout, true);
				}
			// if bytes loaded has changed
			} else {
				if (_isTimeoutRunning) {
					// clear the timer
					_isTimeoutRunning = false;
					Later.abortOperation(_timeoutCaller);
				}
			}
			_lastOverallLoaded = bytesLoaded;
		}

		/**
		 *	Stops the watching and sends the COMPLETE event with the isTimedOut flag set to true.
		 *	Called if the load progress is stuck for the timeout duration.
		 */
		private function callTimeout():void {
			stop();		
			_completeEvent.isTimedOut = true;
			dispatchEvent(_completeEvent);
		}	
	}
}