package org.osmf.player.chrome.widgets {
	import com.adobe.serialization.json.JSON;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;

	public class VodScrubWidget extends Widget {
		private var backDropLeft_played:DisplayObject;
		private var backDropMiddle_played:DisplayObject;
		private var backDropRight_played:DisplayObject;
		private var backDropLeft_loaded:DisplayObject;
		private var backDropMiddle_loaded:DisplayObject;
		private var backDropRight_loaded:DisplayObject;
		private var backDropLeft_empty:DisplayObject;
		private var backDropMiddle_empty:DisplayObject;
		private var backDropRight_empty:DisplayObject;
		private var emptyContainer:Sprite;
		private var loadedContainer:Sprite;
		private var playedContainer:Sprite;
		private var _loadedMask:Sprite;
		private var _playedMask:Sprite;
		private var seeker:Seeker;
		private var _seekTo:Number;
		private var _hintPosition:Number;
		private var _shotsURL:String;
		private var _shotsNum:int;
		private var _imagesArray:Vector.<Bitmap>;
		private var _shotsLoaded:Boolean;
		
		public function VodScrubWidget() {
			super();
		}
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			super.configure(xml, assetManager);
			
			emptyContainer = new Sprite();
			loadedContainer = new Sprite();
			playedContainer = new Sprite();
			
			emptyContainer.mouseEnabled = loadedContainer.mouseEnabled = playedContainer.mouseEnabled = false;
			
			backDropLeft_played = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_WHITE_LEFT); 
			backDropMiddle_played = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_WHITE_MIDDLE); 
			backDropRight_played = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_WHITE_RIGHT); 
			
			backDropLeft_loaded = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_BLUE_LEFT); 
			backDropMiddle_loaded = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_BLUE_MIDDLE); 
			backDropRight_loaded = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_BLUE_RIGHT); 
			
			backDropLeft_empty = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_GRAY_LEFT); 
			backDropMiddle_empty = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_GRAY_MIDDLE); 
			backDropRight_empty = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_GRAY_RIGHT); 
			
			emptyContainer.addChild(backDropLeft_empty);
			emptyContainer.addChild(backDropMiddle_empty);
			emptyContainer.addChild(backDropRight_empty);
			
			loadedContainer.addChild(backDropLeft_loaded);
			loadedContainer.addChild(backDropMiddle_loaded);
			loadedContainer.addChild(backDropRight_loaded);
			_loadedMask = new Sprite();
			loadedContainer.mask = _loadedMask;
			loadedContainer.addChild(_loadedMask);
			
			playedContainer.addChild(backDropLeft_played);
			playedContainer.addChild(backDropMiddle_played);
			playedContainer.addChild(backDropRight_played);
			_playedMask = new Sprite();
			playedContainer.mask = _playedMask;
			playedContainer.addChild(_playedMask);
			
			addChild(emptyContainer);
			addChild(loadedContainer);
			addChild(playedContainer);
			
			seeker = new Seeker();
			seeker.addEventListener(Seeker.SEEK_START, onSeekerStart);
			seeker.addEventListener(Seeker.SEEK_UPDATE, onSeekerUpdate);
			seeker.addEventListener(Seeker.SEEK_END, onSeekerEnd);
			addChild(seeker);
			
			addEventListener(MouseEvent.ROLL_OVER, callShowHint);
			addEventListener(MouseEvent.MOUSE_MOVE, callShowHint);
			addEventListener(MouseEvent.ROLL_OUT, callHideHint);
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			if (availableWidth + availableHeight == 0) { return;}
			backDropMiddle_empty.width = availableWidth - (backDropLeft_empty.width + backDropRight_empty.width);
			backDropMiddle_loaded.width = availableWidth - (backDropLeft_loaded.width + backDropRight_loaded.width);
			backDropMiddle_played.width = availableWidth - (backDropLeft_played.width + backDropRight_played.width);
			
			backDropMiddle_empty.x = backDropLeft_empty.width;
			backDropRight_empty.x = availableWidth - backDropRight_empty.width;
			
			backDropMiddle_loaded.x = backDropLeft_loaded.width;
			backDropRight_loaded.x = availableWidth - backDropRight_loaded.width;
			
			backDropMiddle_played.x = backDropLeft_played.width;
			backDropRight_played.x = availableWidth - backDropRight_played.width;
			seeker.point = new Point(width, height);
		}
		
		private function onSeekerStart(event:Event):void {
			dispatchEvent(new Event(ScrubBar.PAUSE_CALL));
		}
		
		private function onSeekerUpdate(event:Event):void {
			_seekTo = seeker.position;
			dispatchEvent(new Event(ScrubBar.SEEK_CALL));
		}
		
		private function onSeekerEnd(event:Event):void {
			dispatchEvent(new Event(ScrubBar.PLAY_CALL));
		}
		
		private function callShowHint(e:MouseEvent):void {
			_hintPosition = mouseX / width;
			dispatchEvent(new Event(ScrubBar.SHOW_HINT_CALL))
		}
		
		private function callHideHint(e:MouseEvent):void {
			dispatchEvent(new Event(ScrubBar.HIDE_HINT_CALL));
		}
		
		
		public function set loadedPosition(value:Number):void {
			isNaN(value) && (value = 0);
			with (_loadedMask.graphics) {
				clear();
				beginFill(0, 1);
				drawRect(0, 0, value * width, height);
				endFill();
			}
		}
		
		public function set playedPosition(value:Number):void {
			isNaN(value) && (value = 0);
			with (_playedMask.graphics) {
				clear();
				beginFill(0, 1);
				drawRect(0, 0, value * width, height);
				endFill();
			}
		}
		
		public function removeHandlers():void {
			seeker.removeHandlers();
		}
		
		public function getShotAt(position:Number):DisplayObject {
			if (!_shotsLoaded) { return new Sprite(); }
			return _imagesArray[Math.min(int(position * _shotsNum), _shotsNum - 1)];
		}
		
		override public function get width():Number {
			return Math.max(emptyContainer.width, loadedContainer.width, playedContainer.width);
		}
		
		override public function get height():Number {
			return Math.max(emptyContainer.height, loadedContainer.height, playedContainer.height);
		}
		
		public function get seekTo():Number {
			return _seekTo;
		}
		
		public function get hintPosition():Number {
			return _hintPosition;
		}
		
		public function set shotsURL(value:String):void {
			if (!value || _shotsURL == value) { return; }
			_shotsURL = value;
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, shotsInfoLoadedHandler);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, shotsInfoLoadingFailedHandler);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, shotsInfoLoadingFailedHandler);
			urlLoader.load(new URLRequest(_shotsURL));
		}
		
		public function get shotsLoaded():Boolean {
			return _shotsLoaded;
		}
		
		private function shotsInfoLoadingFailedHandler(e:Event):void {
			_shotsURL = '';
			_shotsNum = 0;
			_shotsLoaded = false;
			_imagesArray = null;
		}
		
		private function shotsInfoLoadedHandler(e:Event):void {
			var data:Object = com.adobe.serialization.json.JSON.decode(String(e.currentTarget.data));
			_shotsNum = data.shots_lane_shots;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, shotsInfoLoadingFailedHandler);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, shotsInfoLoadingFailedHandler);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, shotsImageLoadedHandler);
			loader.load(new URLRequest(data.video_thumbnails_url), new LoaderContext(true));
		}
		
		private function shotsImageLoadedHandler(e:Event):void {
			var image:DisplayObject
			try {
				image = (e.currentTarget.content as DisplayObject);
				if (!image) { throw new Error('No image', 404); }
			} catch (error:Error) {
				//Crossdomain access error
				shotsInfoLoadingFailedHandler(e);
				return;
			}
			_imagesArray = new Vector.<Bitmap>();
			var shotWidth:Number = image.width / _shotsNum;
			for (var i:int = 0; i < _shotsNum; i++) {
				var bData:BitmapData = new BitmapData(shotWidth, image.height, false, 0);
				var matrix:Matrix = new Matrix();
				matrix.translate(-shotWidth * i, 0);
				bData.draw(image, matrix, null, null, null, true);
				var bitmap:Bitmap = new Bitmap(bData);
				_imagesArray.push(bitmap);
			}
			_shotsLoaded = true;
		}
	}
}