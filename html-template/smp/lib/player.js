(function(){

	if (!window.PLAYER) {
		window.PLAYER = {};
	}

	PLAYER = {

		init: function(params) {
		    if (!params.src) {
		    	console.log("Ошибка инициализации: не указано видео")
		    	return false;
		    }

			// Формирование id контейнера для плеера
			var containerId;
			if (params.id) {
				containerId = '#' + params.id
				delete params['id']
			} else {
				containerId = '#player'
				console.log("Не указан id контейнера плеера! Используется #player")
			}

			// Формирование перечня параметров плеера
			var options = {
				swf: 'MSPlayer.swf',
				id: 'MSPlayerId',
				src: params.src,
				width: params.width || 640,
				height:  params.height || 462,
				enableStageVideo: true,
				controlBarAutoHide: params.controlBarAutoHide || false,
				playButtonOverlay: true,
				autoPlay: params.autoPlay || true,
				showVideoInfoOverlayOnStartUp: params.showVideoInfo || false
			}
			// Инициализация рекламы
			if (params.ads) {
				// delete params['ads']
				// options['plugin_ads'] = BASEPATH + "plugins/AdvertisementPlugin.swf"
				options = $.extend({}, options, params.ads);
			}
			PLAYER.embedPlayer(containerId, options);
		},

		embedPlayer: function(containerId, options) {
			var $strobemediaplayback = $(containerId);
			$player = $strobemediaplayback.strobemediaplayback(options);
		}
	}
}).call(this);
