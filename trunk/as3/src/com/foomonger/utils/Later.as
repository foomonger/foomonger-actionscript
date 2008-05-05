/*
**********************************************************************************************
foomonger.googlecode.com
Copyright 2008 Foomonger Development
**********************************************************************************************
*/

package com.foomonger.utils {

	import com.foomonger.utils.later.LaterOperation;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public class Later {
		
		private static var _instances:Dictionary;
		private static var _anonymousKey:Object;
		
		private var _timeOperations:Dictionary;
		private var _frameOperations:Dictionary;
		private var _sprite:Sprite;

		// --------------------------------------------------
		//	static functions
		// --------------------------------------------------
		
		public static function getInstance(key:Object = null):Later {			
			if (key == null) {
				if (_anonymousKey == null) {
					_anonymousKey = new Object();
				}
				key = _anonymousKey;
			}			
			if (_instances == null) {
				_instances = new Dictionary(true);
			}			
			if (_instances[key] == null) {
				_instances[key] = new Later();
			}			
			return _instances[key] as Later;
		}
		
		/**
		 * Executes the given function after a number of seconds or frames.
		 * 
		 * @param  func Function to call.
		 * @param duration Number of frames or milliseconds after which to call the given function.
		 * @param useTime If true, duration equals milliseconds. If false, duration equals frames.
		 * @param args Arguments to pass to the given function.
		 * @return LaterOperation
		 */
		public static function call(func:Function, duration:uint = 1, useTime:Boolean = false, ... args):LaterOperation {
			return Later.getInstance().call.apply(null, [func, duration, useTime].concat(args));
		}
		
		/**
		 * Sets the property of the given object to the given value after a number of seconds or frames.
		 * 
		 * @param object Object that contains the property to set.
		 * @param propertyName Name of the property on the object to set.
		 * @param value	Value to set the property to.
		 * @param duration Number of frames or seconds after which to call the given function.
		 * @param useTime If true, duration equals milliseconds. If false, duration equals frames.
		 * @return LaterOperation
		 */
		public static function set(object:Object, propertyName:String, value:Object, duration:uint = 1, useTime:Boolean = false):LaterOperation {
			return Later.getInstance().set.apply(null, [object, propertyName, value, duration, useTime]);
		}
		
		/**
		 * Immediately executes the given operation.
		 * 
		 * @param operation LaterOperation object to execute.
		 * @param caller Pass arguments.callee from the calling function to prevent recursion.
		 */
		public static function finishOperation(operation:LaterOperation, caller:Function = null):void {
			Later.getInstance().finishOperation(operation, caller);
		}
		
		/**
		 * Aborts the given LaterOperation
		 * 
		 * @param operation LaterOperation object to abort.
		 */
		public static function abortOperation(operation:LaterOperation):void {
			Later.getInstance().abortOperation(operation);
		}
		
		
		// --------------------------------------------------
		//	constructor
		// --------------------------------------------------
		
		public function Later() {
			_timeOperations = new Dictionary();
			_frameOperations = new Dictionary();	
			_sprite = new Sprite();
		}
		
		
		// --------------------------------------------------
		//	public functions
		// --------------------------------------------------
		
		/**
		 * Executes the given function after a number of seconds or frames.
		 * 
		 * @param  func Function to call.
		 * @param duration Number of frames or milliseconds after which to call the given function.
		 * @param useTime If true, duration equals milliseconds. If false, duration equals frames.
		 * @param args Arguments to pass to the given function.
		 * @return LaterOperation
		 */
		public function call(func:Function, duration:uint = 1, useTime:Boolean = false, ... args):LaterOperation {
			duration = Math.max(duration, 1);
			
			var operation:LaterOperation = new LaterOperation();
			operation.useTime = useTime;
			operation.func = func;
			operation.duration = duration;
			operation.args = args;
			
			if (useTime) {
				operation.timeoutId = setTimeout(executeOperation, (duration), operation);
				_timeOperations[operation] = operation;
			} else {
				_frameOperations[operation] = operation;
				if (!_sprite.hasEventListener(Event.ENTER_FRAME)) {
					_sprite.addEventListener(Event.ENTER_FRAME, onEnterFrame);
				}
			}
			
			return operation;
		}
		
		
		/**
		 * Sets the property of the given object to the given value after a number of seconds or frames.
		 * 
		 * @param object Object that contains the property to set.
		 * @param propertyName Name of the property on the object to set.
		 * @param value	Value to set the property to.
		 * @param duration Number of frames or milliseconds after which to call the given function.
		 * @param useTime If true, duration equals milliseconds. If false, duration equals frames.
		 * @return LaterOperation
		 */
		public function set(object:Object, propertyName:String, value:Object, duration:uint = 1, useTime:Boolean = false):LaterOperation {
			return call(setObjectProperty, duration, useTime, object, propertyName, value);
		}
		
		/**
		 * Immediately executes the given operation.
		 * 
		 * @param operation LaterOperation object to execute.
		 * @param caller Pass arguments.callee from the calling function to prevent recursion.
		 */
		public function finishOperation(operation:LaterOperation, caller:Function = null):void {
			// if finish's caller was called by Later.call()
			if (caller == operation.func) {
				// avoid recursion, no need to do anything
			} else {
				executeOperation(operation);
			}
		}
		
		/**
		 * Aborts the given LaterOperation
		 * 
		 * @param operation LaterOperation object to abort.
		 */
		public function abortOperation(operation:LaterOperation):void {
			if (operation.useTime) {
				clearTimeout(operation.timeoutId);
				delete _timeOperations[operation];
			} else {
				delete _frameOperations[operation];
			}
		}
		
		/**
		 * Immediately executes all operations.
		 * 
		 * @param caller Pass arguments.callee from the calling function to prevent recursion.
		 */
		public function finishAll(caller:Function = null):void {
			var operation:LaterOperation;
	
			for each (operation in _timeOperations) {
				finishOperation(operation, caller);
			}			
			for each (operation in _frameOperations) {
				finishOperation(operation, caller);
			}
		}
		
		/**
		 * Immediately aborts all operations.
		 */
		public function abortAll():void {
			var operation:LaterOperation;
	
			for each (operation in _timeOperations) {
				abortOperation(operation);
			}			
			for each (operation in _frameOperations) {
				abortOperation(operation);
			}
		}
		
		
		// --------------------------------------------------
		//	private functions
		// --------------------------------------------------
		
		
		/**
		 * Executes the given LaterOperation.
		 */
		private function executeOperation(operation:LaterOperation):void {
			try { 
				operation.func.apply(null, operation.args);
			} catch(e:Error) {
				throw new Error("Error executing function called by Later. Original error message:" + e.message, e.errorID);
			}			
			abortOperation(operation);			
		}
		
		/**
		 * Loops through the LaterOperations that use frames and executes them as neccessary.
		 */
		private function onEnterFrame(event:Event):void {			
			for each (var operation:LaterOperation in _frameOperations) {				
				if (operation.duration > 1) {
					operation.duration--;
				} else {
					executeOperation(operation);
				}
			}
		}
		
		/**
		 * Used by set() to set the property of an object.
		 * 
		 * @param object Object that contains the property to set.
		 * @param propertyName Name of the property on the object to set.
		 * @param value	Value to set the property to.
		 */
		private function setObjectProperty(object:Object, propertyName:String, value:Object):void {
			try {
				object[propertyName] = value;
			} catch (e:Error) {
				throw new Error("Error setting object property. Original error message: " + e.message, e.errorID);
			}
		}
		
				
	}
}