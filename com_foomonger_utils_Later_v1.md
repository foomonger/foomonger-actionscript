## Normal use: ##
```
import com.foomonger.utils.Later;
	
function foo(bar:String):void {
	trace("foo = " + bar);
}
Later.call(this, foo, 12, false, "hello 12 frames later");
Later.call(this, foo, 2000, true, "hello 2000 milliseconds later");
```

## Simplest use: ##
```
import com.foomonger.utils.Later;

function foobar():void {
	trace("foobar");
}

Later.call(this, foobar);	// runs foobar 1 frame later
```

## Property setting use: ##
```
import com.foomonger.utils.Later;
	
function traceBar():void {
	trace("bar: " + bar);
}

var bar:Number = 100;
trace("bar: " + bar);				// outputs "bar: 100"
Later.set(this, "bar", 50, 5, false);		// sets this.bar to 50 after 5 frames
Later.call(this, traceBar, 10, false);		// outputs "bar: 50"
```

## Other features: ##

### To immediately call all functions sent to Later.call() do this: ###
```
Later.finishAll();
```

### To immediately abort all functions sent to Later.call() do this: ###
```
Later.abortAll();
```

### You can also control individual calls to Later.call() by saving the returned object: ###
```
var laterObj:Object = Later.call(this, foo, 12, false, "hello 12 frames later");
```

You can then pass the object to the following functions:
```
Later.abort(laterObj);
Later.finish(laterObj);
```

### You can abort and finish Later calls by groups by using Later.gcall() and Later.gset(). ###
The 5th argument in Later.gcall() is a uint that assigns a group to the Later object.
Use Later.getUniqueGroup() to ensure unique group numbers.
```
import com.foomonger.utils.Later;

function foo(bar:String):void {
        trace(bar);
}

var myGroup:uint = Later.getUniqueGroup();
Later.gcall(this, foo, 12, false, myGroup, "hello world");
Later.gcall(this, foo, 13, false, myGroup, "hello world");
Later.call(this, foo, 14, false, "hello moon");
Later.abortGroup(myGroup);
```
This traces out only "hello moon".