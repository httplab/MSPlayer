package {
	import flash.display.Stage;
	import org.osmf.media.MediaElement;
	import org.osmf.net.StreamingURLResource;
	import org.osmf.traits.LoadTrait;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.PlayTrait;
	import org.osmf.traits.SeekTrait;
	import org.osmf.traits.TimeTrait;
	public class State {
		static private var _instance:State;
		private static var _media:MediaElement;
		private static var _stage:Stage;
		
		public static function obtain():State {
			if (_instance) { 
				throw new SecurityError("State may be created only once", 403);
			}
			_instance = new State();
			return _instance;
		}
		
		public static function isAd():Boolean {
			return _media && _media.metadata.getValue("Advertisement");
		}
		
		public function set stage(value:Stage):void {
			_stage = value;
		}
		
		static public function get displayState():String {
			return _stage ? _stage.displayState : '';
		}
		
		public function set media(value:MediaElement):void {
			_media = value;
		}
		
		public static function get mQSR():MultiQualityStreamingResource {
			if (!_media || !_media.resource || !(_media.resource as MultiQualityStreamingResource)) {
				return null;
			} else {
				return _media.resource as MultiQualityStreamingResource;
			}
		}
		
		public static function get streamType():String {			
			if (!_media || !_media.resource || !(_media.resource as StreamingURLResource)) {
				return "";
			}
			return (_media.resource as StreamingURLResource).streamType;
		}
		
		public static function get timeTrait():TimeTrait {
			return _media ? _media.getTrait(MediaTraitType.TIME) as TimeTrait : null;
		}
		
		public static function get loadTrait():LoadTrait {
			return _media ? _media.getTrait(MediaTraitType.LOAD) as LoadTrait : null;
		}
		
		public static function get seekTrait():SeekTrait {
			return _media ? _media.getTrait(MediaTraitType.SEEK) as SeekTrait : null;
		}
		
		public static function get playTrait():PlayTrait {
			return _media ? _media.getTrait(MediaTraitType.PLAY) as PlayTrait : null;
		}
		
		
	}
}