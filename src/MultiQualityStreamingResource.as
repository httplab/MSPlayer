package {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import org.osmf.net.StreamingURLResource;
	import org.osmf.net.StreamType;
	import com.adobe.serialization.json.JSON;
	
	/**
	 * ...
	 * @author Ilja Mickodin
	 */
	public class MultiQualityStreamingResource extends StreamingURLResource implements IEventDispatcher {
		private var _srcId:int;
		private var _src:String;
		
		static public const RECORDED_DATA_REQUEST:String = "http://www.tvbreak.ru/api/movies/|SRCID|/source.json";
		static public const LIVE_DATA_REQUEST:String = "http://www.tvbreak.ru/api/tv/|SRCID|/source.json";
		static public const STREAM_SRC_BASE:String = "rtmp://w1.msproject.httplab.ru/vod/mp4:";
		static public const STREAM_CHANGED:String = "streamChanged";
		private var versionsArray:Array;
		private var dispatcher:EventDispatcher;
		
		public function MultiQualityStreamingResource(srcId:int, streamType:String = '') {
			super('', streamType);
			dispatcher = new EventDispatcher(this);
			_srcId = srcId;
		}
		
		public function initialize():void {
			var requestURL:String = ((streamType == StreamType.RECORDED) ? RECORDED_DATA_REQUEST : LIVE_DATA_REQUEST).split("|SRCID|").join(_srcId);
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, parseLoadedData);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadFailed);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadFailed);
			urlLoader.load(new URLRequest(requestURL));
		}
		
		private function parseLoadedData(e:Event):void {
			var data:Object = com.adobe.serialization.json.JSON.decode(String(e.currentTarget.data));
			versionsArray = [];
			for each (var versionData:Object in data.versions) {
				var version:Object = { };
				for (var key:String in versionData) {
					version[key] =versionData[key];
				}
				versionsArray.push(versionData);
			}
			loadStream();
		}
		
		private function loadStream(e:Event = null):void {
			var versionIdx:Number = 0;
			if (e) {
				versionIdx = (e.currentTarget as StreamQualitySwitcher).currentStreamIdx;
			}
			for (var key:String in versionsArray[versionIdx]) {
				addMetadataValue(key, versionsArray[versionIdx][key]);
			}
			dispatchEvent(new Event(STREAM_CHANGED));
		}
		
		private function loadFailed(e:Event):void {
			//TODO: Tell about initialization failure
			trace("Sry, guys, i tried to do my best");
		}
		
		public function registerOwnButton(streamQualitySwitcher:StreamQualitySwitcher):void {
			streamQualitySwitcher.addEventListener(StreamQualitySwitcher.STREAM_SWITCHED, loadStream);
			versionsArray.reverse();
			var qualities:Object = { };
			for each (var version:Object in versionsArray) {
				if (version.resolution) {
					qualities[version.resolution.split("x")[1]] = versionsArray.indexOf(version);
				}
			}
			streamQualitySwitcher.registerButtons(qualities);
			streamQualitySwitcher.show();
			versionsArray.reverse();
		}
		
		override public function get url():String {
			if (streamType == StreamType.RECORDED) {
				return STREAM_SRC_BASE + getMetadataValue('filepath').toString();
			}
			return getMetadataValue('url').toString();
		}
		
		override public function set streamType(value:String):void {
			if (streamType) { return; }
			super.streamType = value;
		}
		
		/**
		* EventDispatcher implementation
		*/
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return dispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return dispatcher.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger (type:String):Boolean {
			return dispatcher.willTrigger(type);
		}
	}
}