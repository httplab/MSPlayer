package {
	import com.adobe.serialization.json.JSON;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import org.osmf.net.StreamingURLResource;
	import org.osmf.net.StreamType;
	import org.osmf.player.chrome.widgets.QualitySwitcherContainer;
	import org.osmf.player.elements.ControlBarElement;
	import org.osmf.player.utils.DateUtils;
	
	/**
	 * ...
	 * @author Ilja Mickodin
	 */
	public class MultiQualityStreamingResource extends StreamingURLResource implements IEventDispatcher {
		private var _srcId:int;
		private var _src:String;
		
		static public const RECORDED_DATA_REQUEST:String = "http://new.tvbreak.ru/api/player/movies/|SRCID|/source.json";
		static public const LIVE_DATA_REQUEST:String = "http://new.tvbreak.ru/api/player/tv/|SRCID|/source.json";
		static public const STREAM_CHANGED:String = "streamChanged";
		private var versionsArray:Array;
		private var dispatcher:EventDispatcher;
		private var _shedulesArray:Array;
		private var _currentTitle:String = '';
		
		public function MultiQualityStreamingResource(srcId:int, streamType:String = '') {
			super('', streamType);
			dispatcher = new EventDispatcher(this);
			_srcId = srcId;
			addMetadataValue('srcId', srcId);
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
			var versionsContainer:Object = data;
			versionsContainer = data.versions;
			for each (var versionData:Object in versionsContainer) {
				var version:Object = { };
				for (var key:String in versionData) {
					version[key] =versionData[key];
				}
				versionsArray.push(versionData);
			}
			_currentTitle = (data.info ? data.info.title : '') || '';
			var shedules:Object = (data.info ? data.info.shedule : { } ) || { }
			_shedulesArray = [];
			for each (var sheduleData:Object in shedules) {
				var shedule:Object = {
					start: DateUtils.formatToClientTime(Date.parse(sheduleData.start_at.split('-').join('/'))),
					title: sheduleData.title
				}
				_shedulesArray.push(shedule);
			}
			loadStream();
		}
		
		private function loadStream(e:Event = null):void {
			var versionIdx:Number = 0;
			if (e) {
				versionIdx = e.currentTarget.currentStreamIdx;
			}
			for (var key:String in versionsArray[versionIdx]) {
				addMetadataValue(key, versionsArray[versionIdx][key]);
			}
			if (getMetadataValue('dvr')) {
				streamType = StreamType.DVR;
			} else {
				streamType = StreamType.LIVE;
			}
			dispatchEvent(new Event(STREAM_CHANGED));
		}
		
		private function loadFailed(e:Event):void {
			//TODO: Tell about initialization failure
			trace("Sry, guys, i tried to do my best");
		}
		
		public function registerOwnButton(controlBar:ControlBarElement):void {
			controlBar.addEventListener(QualitySwitcherContainer.STREAM_SWITCHED, loadStream);
			var qualities:Array = [];
			for each (var version:Object in versionsArray) {
				if (version.resolution) {
					qualities.push(version.resolution.split("x")[1]);
				} else if (version.quality) {
					version.quality = version.quality.replace('low', 'Низкое');
					version.quality = version.quality.replace('medium', 'Хорошее');
					version.quality = version.quality.replace('hight', 'Высокое');
					version.quality = version.quality.replace('high', 'Высокое');
					qualities.push(version.quality);
				}
			}
			controlBar.configureStreamQualitySwitcher(qualities);
		}
		
		override public function get url():String {
			if (streamType == StreamType.RECORDED) {
				return getMetadataValue('filepath').toString();
			}
			return getMetadataValue('url').toString();
		}
		
		public function get shotsURL():String {
			if (streamType != StreamType.RECORDED) { return ''; }
			return 'http://mp.httplab.ru:3000/api/tasks/' + getMetadataValue('task_id');
		}
		
		override public function set streamType(value:String):void {
			if (streamType == StreamType.RECORDED) { return; }
			super.streamType = value;
		}
		
		public function get shedulesArray():Array {
			return _shedulesArray.concat();
		}
		
		public function get currentTitle():String {
			return _currentTitle;
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