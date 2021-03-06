package {
	import com.bigp.utils.TimerUtils;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Pierre Chamberlain
	 */
	public class AIRFileServer extends AIRFileServerUI {
		[Embed(source="../application.xml", mimeType="application/octet-stream")]
		public static const APPLICATION_XML:Class;
		
		private var proc:NativeProcess;
		private var procResult:String;
		private var _currentFileMode:String;
		
		protected var _canUseCommands:Boolean = false;
		
		
		public function AIRFileServer():void {
			super();
			
			var xApp:XML = XML(new APPLICATION_XML());
			log("version: " + xApp.children()[1] );
			_connectionName = "localhost:" + _connectionName;
			
			if (!NativeProcess.isSupported) {
				log("Native Process not supported at the moment.\n (only works in native install).");
			} else {
				_canUseCommands = true;
			}
			
			log("Waiting for LocalConnections for file-writing requests...");
		}
		
		public function startCommand( pCommandName:String, pArgs:Array ):NativeProcess {
			var exePath:File = resolvePath( pCommandName );
			
			if (!_canUseCommands) {
				log("Could not start command: " +  exePath.nativePath );
				return null;
			} else if(!exePath.exists){
				log("Start command does not exists: " + exePath.nativePath );
				return null;
			}
			
			
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.executable = exePath;
			info.arguments = array2Vector(pArgs);
			
			procResult = "";
			
			proc = new NativeProcess();
			proc.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onProcessOutput);
			proc.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onProcessError);
			proc.addEventListener(NativeProcessExitEvent.EXIT, onProcessExit);
			proc.start(info);
			return proc;
		}
		
		private function onProcessExit(e:NativeProcessExitEvent):void {
			log("Exit code: " + e.exitCode);
			_conn.send(_connectionName, "receiveStartCommand", procResult);
		}
		
		private function onProcessError(e:ProgressEvent):void {
			log("Error data: " + proc.standardOutput.readUTFBytes(proc.standardError.bytesAvailable));
		}
		
		private function onProcessOutput(e:ProgressEvent):void {
			procResult += proc.standardOutput.readUTFBytes(proc.standardOutput.bytesAvailable);
			log("Standard data: " + procResult);
		}
		
		private static function str2bytes(pString:String):ByteArray {
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes(pString);
			return bytes;
		}
		
		private function writeBytesToFile(pFilePath:String, pData:ByteArray, pWriteMode:String):void {
			TimerUtils.delayKill(logClear);
			
			var file:File;
			if (pFilePath.indexOf(":") === 1) {
				file = new File(pFilePath);
			} else {
				file = File.desktopDirectory.resolvePath(pFilePath);
			}
			
			pData.position = 0;
			
			pFilePath = file.nativePath;
			_currentPath = pFilePath;
			_currentFileMode = pWriteMode;
			var fileStream:FileStream = new FileStream();  
			fileStream.addEventListener(Event.CLOSE, onFileComplete);
			fileStream.openAsync(file, pWriteMode);
			fileStream.writeBytes(pData);
			fileStream.close();
		}
		
		private function onFileComplete(e:Event):void {
			var action:String = _currentFileMode == FileMode.APPEND ? "Appended: " : "Written: ";
			log(action + _currentPath);
			TimerUtils.delay(2500, logClear);
		}
		
		public function checkConnection():void {
			//Empty function just to safely execute the client "handshake" method.
			log("New client connection detected.");
			_conn.send(_connectionName, "receiveCheckConnection");
		}
		
		public function maintainConnection():void {
			_conn.send(_connectionName, "receiveMaintainConnection");
		}
		
		public function saveText(pFilePath:String, pContent:String):void {
			writeBytesToFile(pFilePath, str2bytes(pContent), FileMode.WRITE);
		}
		
		public function appendText(pFilePath:String, pContent:String):void {
			writeBytesToFile(pFilePath, str2bytes(pContent), FileMode.APPEND);
		}
		
		public function saveBytes(pFilePath:String, pData:ByteArray):void {
			writeBytesToFile( pFilePath, pData, FileMode.WRITE );
		}
		
		public function appendBytes(pFilePath:String, pData:ByteArray):void {
			writeBytesToFile( pFilePath, pData, FileMode.APPEND );
		}
		
		public function listDirectory(pFilePath:String):void {
			var file:File = resolvePath(pFilePath);
			
			var theFiles:Array = file.getDirectoryListing();
			var theResults:Array = [];
			for (var f:int = 0, fLen:int = theFiles.length; f < fLen; f++) {
				var theFile:File = theFiles[f];
				theResults[theResults.length] = theFile.nativePath;
			}
			
			_conn.send(_connectionName, "receiveListDirectory", theResults);
		}
		
		public function createDirectory(pFilePath:String):void {
			var file:File = resolvePath(pFilePath);
			file.createDirectory();
			_conn.send(_connectionName, "receiveCreateDirectory", file.nativePath);
		}
		
		public function deleteDirectory(pFilePath:String, pAndContent:Boolean):void {
			var file:File = resolvePath(pFilePath);
			file.deleteDirectory(pAndContent);
			_conn.send(_connectionName, "receiveDeleteDirectory", file.nativePath);
		}
		
		public function deleteFile(pFilePath:String):void {
			var file:File = resolvePath(pFilePath);
			file.deleteFile();
			_conn.send(_connectionName, "receiveDeleteFile", file.nativePath);
		}
	}
	
}