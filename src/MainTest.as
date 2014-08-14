package  {
	import bigp.AIRFileSaveClient;
	import bigp.AIRFileSaveHandler;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.utils.ByteArray;
	

	/**
	 * ...
	 * @author Pierre Chamberlain
	 */
	public class MainTest extends Sprite {
		private var client:AIRFileSaveClient;
		private var fileHandler:AIRFileSaveHandler;
		
		public function MainTest() {
			super();
			
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event=null):void {
			e && removeEventListener(Event.ADDED_TO_STAGE, init);
			
			client = new AIRFileSaveClient();
			fileHandler = client.open("test.json", onLoaded, onError);
			stage.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		private function onError():void {
			trace("File not found.");
		}
		
		private function onLoaded():void {
			trace("fileHandler: " + fileHandler.data);
		}
		
		private function onClick(e:MouseEvent):void {
			/*
			trace("Attempting to write file...");
			
			writer.saveText("../../folder1/folder2/testing.txt", "Another test.");
			//writer.saveText("W:\\testing.txt", "Another test.");
			
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes("Bytes test.");
			//writer.saveBytes("W:\\testing_bytes.txt", bytes);
			*/
			
			//writer.listDirectory("../", onFileNames);
			client.startCommand("test.bat", ["hello", "world"], onStartCommandDone);
		}
		
		private function onStartCommandDone(pResult:String):void {
			trace("The result is: " + pResult);
		}
		
		private function onFileNames(pFileNames:Array):void {
			trace("Filenames: \n  " + pFileNames.join("\n  "));
		}
	}
}