package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.text.TextField;
	import org.osmf.media.MediaElement;
	import org.osmf.net.StreamType;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.chrome.widgets.AutoHideWidget;
	import org.osmf.player.chrome.widgets.WidgetIDs;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.PlayTrait;
	import org.osmf.traits.TimeTrait;

	public class TitleWidget extends AutoHideWidget {
		private var playTrait:PlayTrait;
		static public const MIN_WITDH:Number = 770;
		private static const _requiredTraits:Vector.<String> = new Vector.<String>;
		private var titleDisplayObject:ASSET_player_title;
		private var resource:MultiQualityStreamingResource;
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			id = WidgetIDs.TITLE_WIDGET;
			fadeSteps = 6;			
			titleDisplayObject = new ASSET_player_title();
			addChild(titleDisplayObject);
			measure();
			super.configure(xml, assetManager);
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			if (!availableWidth || !availableHeight) { return; }
			super.layout(availableWidth, availableHeight, deep);
			width = availableWidth;
		}
		
		override public function set width(value:Number):void {
			//super.width = value;
			if (value < MIN_WITDH) {
				titleDisplayObject.parent && removeChild(titleDisplayObject);
			} else {
				addChild(titleDisplayObject);
				fit(value);
			}
		}
		
		private function fit(value:Number):void {
			titleDisplayObject.bg.width = value;
			titleDisplayObject.titleTxt.width = Math.max(.45 * value, 350);
			titleDisplayObject.nameTxt.width = Math.max(.45 * value, 350);
			titleDisplayObject.nameTxt.x = width - titleDisplayObject.nameTxt.width - titleDisplayObject.titleTxt.x;
			fitTextHeight(titleDisplayObject.nameTxt);
			fitTextHeight(titleDisplayObject.titleTxt);
		}
		
		override public function set media(value:MediaElement):void {
			super.media = value;
			if (value && value.metadata) {
                setSuperVisible(!value.metadata.getValue("Advertisement"));
            }
			if (media && (media.resource) && (media.resource is MultiQualityStreamingResource)) {
				resource = (media.resource as MultiQualityStreamingResource)
			}
			renewTexts();
		}
		
		private function renewTexts():void {
			titleDisplayObject.titleTxt.wordWrap = titleDisplayObject.nameTxt.wordWrap = true;
			titleDisplayObject.titleTxt.multiline = titleDisplayObject.nameTxt.multiline = true;
			titleDisplayObject.nameTxt.text = resource ? resource.currentTitle : '';
			if (timeTrait && resource.streamType != StreamType.RECORDED) {
				//Перебираем массив задач и ищем наиболее близкую к текущему просматриваемому времени в прошлом
				var date:Date = new Date();
				date.setTime(date.time - (1 - (timeTrait.currentTime / timeTrait.duration)) * thims);
				var currentShedule:Object;
				for each (var shedule:Object in resource.shedulesArray) {
					if (shedule.start > date) { break; }
					!currentShedule && (currentShedule = shedule);
					(currentShedule.start < shedule.start) && (currentShedule = shedule);
				}
				titleDisplayObject.titleTxt.text = currentShedule ? currentShedule.title : '';
			} else {
				titleDisplayObject.titleTxt.text = '';
			}
			fitTextHeight(titleDisplayObject.titleTxt);
			fitTextHeight(titleDisplayObject.nameTxt);
		}
		
		private function fitTextHeight(tf:TextField):void {
			tf.wordWrap = tf.multiline = true;
			tf.height = Math.min(Math.max(tf.textHeight * tf.numLines, tf.height), height);
		}
		
		public function get timeTrait():TimeTrait {
			return media ? media.getTrait(MediaTraitType.TIME) as TimeTrait : null;
		}
		
		protected function get thims():Number {
			return LiveScrubWidget.TWO_HOURS_IN_MILLISECONDS;
		}
		
		override public function set x(value:Number):void {
			super.x = 0;
		}
		
		override public function set y(value:Number):void {
			super.y = 0;
		}
		
		override public function get measuredWidth():Number {
			return width;
		}
		
		override public function get measuredHeight():Number {
			return height;
		}
		
		override public function get width():Number {
			return titleDisplayObject.width;
		}
		
		override public function get height():Number {
			return titleDisplayObject.height;
		}
	}
}