(function(){

	if (!window.PLAYER) {
		window.PLAYER = {};
	}

	BASEPATH = 'http://httplab.ru/mediasystem/smp/';

	PLAYER = {

		init: function(params) {
		    if (!params.src) {
		    	console.log("Ошибка инициализации: Не указано видео")
		    	return false;
		    }

			// Формирование id контейнера для плеера
			var containerId;
			if (params.id) {
				containerId = 'msplayer-' + Date.now();
				var rootContainer = $('#' + params.id);
				rootContainer.find('[id^=msplayer]').remove();
				rootContainer.find('object').remove();
				$("<div id='" + containerId + "'></div>").appendTo(rootContainer);
				delete params['id'];
				containerId = '#' + containerId;
			} else {
				console.log("Ошибка инициализации: Не указан id контейнера плеера!")
			}

			// Формирование перечня параметров плеера
			var options = {
				//swf: BASEPATH + 'MSPlayer.3.swf',
				id: 'strobeMediaPlaybackId',
				src: params.src,
				streamType: params.streamType || 'live',
				width: params.width || 640,
				height:  params.height || 462,
				enableStageVideo: true,
				controlBarAutoHide: params.controlBarAutoHide || false,
				playButtonOverlay: true,
				controlBarMode: params.controlBarMode || 'floating',
				controlBarAutoHide: params.controlBarAutoHide || true,
				autoPlay: params.autoPlay,
				showVideoInfoOverlayOnStartUp: params.showVideoInfo || false
			}

			// Принудительная инициализация рекламы
		// 	if (!params.preRoll) {
		//       	params["preRoll"] = "http://cdn1.eyewonder.com/200125/instream/osmf/vast_1_linear_flv.xml"
		// 	}

			options = $.extend({}, params, options);
			PLAYER.embedPlayer(containerId, options);
		},

		embedPlayer: function(containerId, options) {
			var $strobemediaplayback = $(containerId);
			$player = $strobemediaplayback.strobemediaplayback(options);
		}
	}
}).call(this);
