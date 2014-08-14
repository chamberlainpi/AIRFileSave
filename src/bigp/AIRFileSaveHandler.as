package bigp {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;

	/**
	 * ...
	 * @author Pierre Chamberlain
	 */
	public class AIRFileSaveHandler {
		public static var DEFAULT_JSON_PARSE:Function;
		public static var DEFAULT_JSON_STRINGIFY:Function;
		public static const TYPE_00_UNKNOWN:int = 0;
		public static const TYPE_01_TEXT:int = 1;
		public static const TYPE_02_JSON:int = 2;
		public static const TYPE_03_XML:int = 2;
		public static const TYPE_03_IMAGE:int = 3;
		public static const TYPE_04_SOUND:int = 4;
		
		private var _client:AIRFileSaveClient;
		private var _loader:URLLoader;
		
		public var data:Object;
		public var filePath:String;
		public var fileType:int = TYPE_00_UNKNOWN;
		public var jsonIsPrettyPrinted:Boolean = true;
		
		public var onError:Function;
		public var onLoaded:Function;
		
		public function AIRFileSaveHandler(pFilePath:String, pClient:AIRFileSaveClient) {
			filePath = pFilePath;
			_client = pClient;
			
			if(DEFAULT_JSON_PARSE==null || DEFAULT_JSON_STRINGIFY==null) {
				var nativeJSON:Class = ApplicationDomain.currentDomain.getDefinition("JSON") as Class;
				trace("Using default JSON methods: " + nativeJSON);
				if (DEFAULT_JSON_PARSE == null) DEFAULT_JSON_PARSE = nativeJSON.parse;
				if (DEFAULT_JSON_STRINGIFY == null) DEFAULT_JSON_STRINGIFY = nativeJSON.stringify;
			}
		}
		
		public function load():void {
			_loader = new URLLoader();
			_loader.addEventListener(Event.COMPLETE, onFileLoaded);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, onFileError);
			_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileError);
			_loader.load( new URLRequest(filePath) );
		}
		
		public function save():void {
			if(fileType==TYPE_02_JSON) {
				var theContent:String = DEFAULT_JSON_STRINGIFY(data, null, jsonIsPrettyPrinted ? "\t" : null);
				_client.saveText(filePath, theContent);
			} else if(fileType==TYPE_01_TEXT) {
				_client.saveText(filePath, String(data));
			} else {
				_client.saveBytes(filePath, ByteArray(data));
			}
		}
		
		private function onFileLoaded(e:Event):void {
			var theExtension:String = filePath.split(".").pop();
			switch(theExtension) {
				case "jsfl":
				case "as":
				case "txt": fileType = TYPE_01_TEXT; break;
				case "json": fileType = TYPE_02_JSON; break;
				case "jpg":
				case "png":
				case "gif": fileType = TYPE_03_IMAGE; break;
				default: fileType = TYPE_00_UNKNOWN; break;
			}
			
			if (fileType===TYPE_02_JSON) {
				data = DEFAULT_JSON_PARSE(_loader.data);
			} else {
				data = _loader.data;
			}
			
			if (onLoaded!=null) onLoaded();
		}
		
		private function onFileError(e:Event=null):void {
			if (onError != null) onError();
		}
	}
}