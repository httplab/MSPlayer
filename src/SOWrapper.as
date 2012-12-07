package {
	import flash.net.SharedObject;
	import org.osmf.events.AudioEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.player.media.StrobeMediaPlayer;
	public class SOWrapper {
		
		private static var sharedObject:SharedObject = SharedObject.getLocal("MSPlayer");
		
		static public function processPlayer(player:StrobeMediaPlayer, isSavePosition:Boolean = true):void {
			if (sharedObject.data.currentVolume) {
				player.volume = sharedObject.data.currentVolume;
			} else {
				sharedObject.data.currentVolume = player.volume;
			}
			if (sharedObject.data.mutedState) {
				player.muted = sharedObject.data.mutedState;
			} else {
				sharedObject.data.mutedState = player.muted;
			}
			player.removeEventListener(AudioEvent.VOLUME_CHANGE, onVolumeChange);
			player.removeEventListener(AudioEvent.MUTED_CHANGE, onMutedChange);
			player.removeEventListener(TimeEvent.CURRENT_TIME_CHANGE, onCurrentTimeChangeForSaveState);
			player.addEventListener(AudioEvent.VOLUME_CHANGE, onVolumeChange);
			player.addEventListener(AudioEvent.MUTED_CHANGE, onMutedChange);
			isSavePosition && player.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, onCurrentTimeChangeForSaveState);
		}
		
		static public function setCurrentVideoTime(player:StrobeMediaPlayer, parameters:Object):void {
			var currentSrc:String = parameters.src;
			if (sharedObject.data.src && sharedObject.data.src == currentSrc) {
				if (sharedObject.data.currentTimePosition && player.canSeek) {
					player.seek(sharedObject.data.currentTimePosition);
				}
			} else {
				sharedObject.data.src = currentSrc;
			}
		}
		
		private static function onVolumeChange(event:AudioEvent):void {
			sharedObject.data.currentVolume = event.volume;
		}
		
		private static function onMutedChange(event:AudioEvent):void {
			sharedObject.data.mutedState = event.muted;
		}
		
		private static function onCurrentTimeChangeForSaveState(event:TimeEvent):void {
			sharedObject.data.currentTimePosition = event.time;
		}
	}
}