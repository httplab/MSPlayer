package org.osmf.player.elements {
	import com.adobe.serialization.json.JSON;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import org.osmf.layout.LayoutMetadata;
	import org.osmf.media.MediaElement;
	import org.osmf.net.StreamType;
	import org.osmf.player.chrome.ChromeProvider;
	import org.osmf.player.chrome.widgets.ChannelListButton;
	import org.osmf.player.chrome.widgets.ChannelListDialog;
	import org.osmf.player.configuration.PlayerConfiguration;
	import org.osmf.traits.DisplayObjectTrait;
	import org.osmf.traits.MediaTraitType;
	
	
	public class ChannelListDialogElement extends MediaElement {
		private var _jsCallbackFunctionName:String = '';
		static public const CHANNEL_CHANGED:String = "channelChanged";
		static public const ALL_CHANNELS:String = "Все каналы";
		static public const DEFAULT_CHANNELS_LIST_URL:String = "http://www.tvbreak.ru/api/tvslice";
		private var channelListDialog:ChannelListDialog;
		private var chromeProvider:ChromeProvider;
		private var _configuration:PlayerConfiguration;
		
		public function ChannelListDialogElement(configuration:PlayerConfiguration) {
			_configuration = configuration;
		}
		
		override protected function setupTraits():void {
			chromeProvider = ChromeProvider.getInstance();
			channelListDialog = chromeProvider.createChannelListDialog();
			channelListDialog.measure();			
			channelListDialog.addEventListener(ChannelListButton.LIST_CALL, dispatchEvent);			
			channelListDialog.addEventListener(ChannelListButton.LIST_CLOSE_CALL, dispatchEvent);			
			if (channelListDialog.stage) {
				addStageResizeListeners(null);
			} else {
				channelListDialog.addEventListener(Event.ADDED_TO_STAGE, addStageResizeListeners);
			}
			addMetadata(LayoutMetadata.LAYOUT_NAMESPACE, channelListDialog.layoutMetadata);
			var viewable:DisplayObjectTrait = new DisplayObjectTrait(channelListDialog, channelListDialog.measuredWidth, channelListDialog.measuredHeight);
			addTrait(MediaTraitType.DISPLAY_OBJECT, viewable);				
			super.setupTraits();			
		}
		
		private function addStageResizeListeners(e:Event):void {
			channelListDialog.removeEventListener(Event.ADDED_TO_STAGE, addStageResizeListeners);
			channelListDialog.stage.removeEventListener(FullScreenEvent.FULL_SCREEN, fullScreenSwitching);
			channelListDialog.stage.addEventListener(FullScreenEvent.FULL_SCREEN, fullScreenSwitching);
		}
		
		private function fullScreenSwitching(e:FullScreenEvent):void {
			dispatchEvent(new Event(ChannelListButton.LIST_CLOSE_CALL));
		}
		
		public function renewContent(url:String):void {
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(url);
			loader.addEventListener(Event.COMPLETE, parseLoadedData);
			loader.addEventListener(IOErrorEvent.IO_ERROR, loadFailed);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadFailed);
			loader.load(request);
		}
		
		private function parseLoadedData(e:Event):void {
			var data:Object = com.adobe.serialization.json.JSON.decode(String(e.currentTarget.data));
			var groups:Vector.<ChannelGroup> = new Vector.<ChannelGroup>();
			var allChannels:ChannelGroup = new ChannelGroup(ALL_CHANNELS);
			var channelData:Object;
			var channel:Channel;
			var programs:Object = { };
			for each (var program:Object in data.programms) {
				programs[program.channel_id] = {
					title: program.title,
					time: program.start
				}
			}
			for each (channelData in data.all_channels) {
				channel = allChannels.addChannel(channelData);
				channel.addEventListener(MouseEvent.MOUSE_DOWN, channelSelected);
				if (programs[channel.srcId]) {
					channel.setBroadcast(programs[channel.srcId].time,programs[channel.srcId].title)
				}
			}
			groups.push(allChannels);
			var group:ChannelGroup
			for each (var groupData:Object in data.categories) {
				group = new ChannelGroup(groupData.category_name);
				for each (channelData in groupData.programs) {
					channel = group.addChannel(channelData);
					channel.addEventListener(MouseEvent.MOUSE_DOWN, channelSelected);
					if (programs[channel.srcId]) {
						channel.setBroadcast(programs[channel.srcId].time, programs[channel.srcId].title)
					}
				}
				groups.push(group);
			}
			channelListDialog.content = groups;
		}
		
		private function channelSelected(e:MouseEvent):void {
			var channel:Channel = (e.currentTarget as Channel);
			_configuration.srcId = channel.srcId;
			_configuration.type = StreamType.LIVE;
			_jsCallbackFunctionName && 
				ExternalInterface.available && 
				ExternalInterface.call(_jsCallbackFunctionName, channel.srcId);
			dispatchEvent(new Event(ChannelListButton.LIST_CLOSE_CALL));
			dispatchEvent(new Event(CHANNEL_CHANGED));
		}
		
		private function loadFailed(e:Event):void {
			//TODO: Tell about initialization failure
			trace("Sry, guys, i tried to do my best");
		}
		
		public function showDialog():void {
			channelListDialog.x = 0;
			channelListDialog.y = 0;
		}
		
		public function set jsCallbackFunctionName(value:String):void {
			_jsCallbackFunctionName = value;
		}
	}
}