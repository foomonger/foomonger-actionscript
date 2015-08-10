## Note: ##
Not only does the LoadWatcher consolidate the loaded bytes, but it also accounts for the browser downloading a limited number of items at a time.  The `percent` property in the `PROGRESS` event reflects the adjustment.  If you use the straight bytesLoaded/bytesTotal, then the value can reach 100% and drop back down when the browser has started to load the rest of the items you passed.

## Events: ##

### LoadWatcherEvent.PROGRESS: ###
Called on enterframe while items are loading.
Use can use `bytesLoaded` and `bytesTotal` from the event object, but you'll probably just use `progress`.

### LoadWatcherEvent.COMPLETE: ###
Called when everything has loaded or a timeout has occurred.  A timeout occurs if the load progress is stuck for a set duration (i.e. one of the files doesn't load).  The default timeout duration is 30 seconds.

### LoadWatcherEvent.COMPLETE\_INIT: ###
Called 1 frame after a non-timeout `COMPLETE` event has dispatched.  This helps with data initialization.

## AS2 Example: ##
```
// requires an images folder with jpgs

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
```

## AS3 Example: ##
```
// requires an images folder with jpgs

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
```