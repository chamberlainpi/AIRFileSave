package  {
	import com.bigp.Lib;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.StatusEvent;
	import flash.filesystem.File;
	import flash.net.LocalConnection;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	/**
	 * ...
	 * @author Pierre Chamberlain
	 */
	public class AIRFileServerUI extends Sprite {
		
		[Embed(source="../bin-client/AIRFileSaveClient.swc", mimeType="application/octet-stream")]
		private static const SWC_RAW:Class;
		
		private static var INST:AIRFileServerUI;
		
		protected var _label:TextField;
		protected var _connShortName:String = "connection";
		
		protected var _currentPath:String;
		protected var _conn:LocalConnection;
		protected var swcFile:File;
		protected var swcButton:Sprite;
		
		public function AIRFileServerUI() {
			super();
			
			Lib.preload(this, onReady);
		}
		
		protected function onReady():void {
			Lib.initInfo();
			
			INST = this;
			
			var tf:TextFormat = new TextFormat("Lucida Console", 10, 0x00ffff);
			_label = new TextField();
			_label.width = stage.stageWidth;
			_label.height = stage.stageHeight;
			_label.autoSize = TextFieldAutoSize.LEFT;
			_label.wordWrap = true;
			_label.multiline = true;
			_label.defaultTextFormat = tf;
			
			addChild(_label);
			
			prepareSWCDownloader();
			prepareLocalConnection();
		}
		
		public static function array2Vector(pArr:Array):Vector.<String> {
			var results:Vector.<String> = new Vector.<String>();
			for (var a:int = 0, aLen:int = pArr.length; a < aLen; a++) {
				results[a] = pArr[a];
			}
			return results;
		}
		
		public static function resolvePath(pFilePath:String):File {
			var theFile:File;
			if (pFilePath.indexOf(":") === 1) {
				theFile = new File(pFilePath);
			} else {
				theFile = File.desktopDirectory.resolvePath(pFilePath);
			}
			return theFile;
		}
		
		protected function prepareSWCDownloader():void {
			swcButton = new Sprite();
			
			var g:Graphics = swcButton.graphics;
			var theWidth:Number = 60;
			var theHeight:Number = 20;
			g.lineStyle(2, 0xffffff, 1, true);
			g.beginFill(0xff8811, 1);
			g.drawRoundRect(0, 0, theWidth, theHeight, 5, 5);
			
			var swcLabel:TextField = new TextField();
			swcLabel.defaultTextFormat = new TextFormat("Arial", 10, 0xffffff);
			swcLabel.autoSize = TextFieldAutoSize.LEFT;
			swcLabel.text = "Get SWC";
			swcLabel.x = (theWidth - swcLabel.textWidth) * .5 - 4;
			swcLabel.y = (theHeight - swcLabel.textHeight) * .5 - 4;
			swcButton.x = stage.stageWidth - theWidth - 10;
			swcButton.y = 10;
			swcButton.alpha = 0.5;
			swcButton.mouseChildren = false;
			swcButton.buttonMode = true;
			swcButton.addEventListener(MouseEvent.CLICK, onSWCClick);
			swcButton.addEventListener(MouseEvent.ROLL_OVER, onSWCRoll);
			swcButton.addEventListener(MouseEvent.ROLL_OUT, onSWCRoll);
			swcButton.addChild(swcLabel);
			addChild(swcButton);
		}
		
		protected function prepareLocalConnection():void {
			log("Waiting for LocalConnections for file-writing requests:");
			
			_conn = new LocalConnection();
			_conn.allowDomain("*");
			_conn.allowInsecureDomain("*");
			_conn.addEventListener(StatusEvent.STATUS, onStatus);
			_conn.client = this;
			_conn.connect(_connShortName);
			_conn.client = this;
		}
		
		private function onStatus(e:StatusEvent):void {
			log("Connection Status: " + e.code);
		}
		
		protected function onSWCRoll(e:MouseEvent):void {
			swcButton.alpha = e.type === MouseEvent.ROLL_OVER ? 1 : 0.5;
		}
		
		protected function onSWCClick(e:MouseEvent):void {
			e.preventDefault();
			e.stopImmediatePropagation();
			e.stopPropagation();
			
			if (swcFile) {
				swcFile.removeEventListener(Event.COMPLETE, onSWCSaved);
				swcFile = null;
			}
			
			swcFile = File.desktopDirectory;
			swcFile.addEventListener(Event.COMPLETE, onSWCSaved);
			swcFile.save(new SWC_RAW(), "AIRFileSaveClient.swc");
		}
		
		private function onSWCSaved(e:Event):void {
			var thePath:String = swcFile.nativePath;
			log("Saving SWC to: " + thePath);
		}
		
		public static function log(str:*):void {
			trace(str);
			INST._label.appendText(str + "\n");
		}
		
		public static function logClear():void {
			INST._label.text = "";
		}
	}
}