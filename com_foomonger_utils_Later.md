Below is a class that shows some examples. It just calls traces, but add tween methods and you have extensive animation possibilities.

For the v1 version of this page, click here: [com\_foomonger\_utils\_Later\_v1](com_foomonger_utils_Later_v1.md)

```
package {
	
	import com.foomonger.utils.Later;
	import com.foomonger.utils.later.LaterOperation;
	
	import flash.display.Sprite;

	public class LaterExamples extends Sprite {
		
		public function LaterExamples() {			
			simpleExample();			
			//finishExample();
			//abortExample();
			//simpleGroupExample();
			//groupFinishAllExample();
			//groupAbortAllExample();
		}
		
		private function simpleExample():void {			
			Later.call(trace, 50, false, "o");
			Later.call(trace, 40, false, "l");
			Later.call(trace, 30, false, "l");
			Later.call(trace, 20, false, "e");
			Later.call(trace, 10, false, "h");
			
			/*
			outputs:
				h
				e
				l
				l
				o
			*/
			
		}
				
		private function finishExample():void {
			var operation:LaterOperation;
			
			operation = Later.call(trace, 50, false, "o");
			Later.call(trace, 40, false, "l");
			Later.call(trace, 30, false, "l");
			Later.call(trace, 20, false, "e");
			Later.call(trace, 10, false, "h");
			
			Later.finishOperation(operation);
			
			/*
			outputs:
				o
				h
				e
				l
				l
			*/
		}
		
		private function abortExample():void {
			var operation:LaterOperation;
			
			operation = Later.call(trace, 10, false, "hello");
			Later.call(trace, 20, false, "world!");
			
			Later.abortOperation(operation);
			
			/*
			outputs:
				world!
			*/
		}
		
		private function simpleGroupExample():void {
			var that:Object = new Object();
			Later.getInstance(this).call(trace, 10, false, "hello");
			Later.getInstance(that).call(trace, 20, false, "world");
			Later.getInstance(that).call(trace, 25, false, "!");
			/*
			outputs:
				hello
				world
				!
			*/
		}
		
		private function groupFinishAllExample():void {
			var that:Object = new Object();
			Later.getInstance(this).call(trace, 10, false, "hello");
			Later.getInstance(that).call(trace, 20, false, "world");
			Later.getInstance(that).call(trace, 25, false, "!");
			Later.getInstance(that).finishAll();
			/*
			outputs:
				world
				!
				hello				
			*/
		}
		
		private function groupAbortAllExample():void {
			var that:Object = new Object();
			Later.getInstance(this).call(trace, 10, false, "hello");
			Later.getInstance(that).call(trace, 20, false, "world");
			Later.getInstance(that).call(trace, 25, false, "!");
			Later.getInstance(that).abortAll();
			/*
			outputs:
				hello				
			*/
		}
		
	}
}

```