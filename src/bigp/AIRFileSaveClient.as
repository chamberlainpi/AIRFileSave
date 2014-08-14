package bigp {
	import flash.display.LoaderInfo;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;

	/**
	 * ...
	 * @author Pierre Chamberlain
	 */
	public class AIRFileSaveClient {
		private var _connOutput:LocalConnection;
		private var _connSimpleName:String = "connection";
		private var _connName:String = "app#AIRFileSave:" + _connSimpleName;
		private var _localFolder:String;
		private var _lastURI:String;
		private var _resolvedURI:String;
		private var _receiver:clsAIRClientReceiver;
		
		public function AIRFileSaveClient(pSecureLoaderInfo:LoaderInfo=null) {
			_connOutput = createConnection();
			_connOutput.addEventListener(StatusEvent.STATUS, onStatus);
			
			_receiver = new clsAIRClientReceiver(this);
			_receiver._connInput = createConnection();
			_receiver._connInput.client = _receiver;
			_receiver._connInput.connect(_connSimpleName);
			
			//Resolve the local folder:
			var theLoaderInfo:LoaderInfo = pSecureLoaderInfo || LoaderInfo.getLoaderInfoByDefinition(ApplicationDomain.currentDomain);
			var thePath:String = theLoaderInfo.url;
			var thePathArr:Array = thePath.replace("file:///", "").split("/");
			thePathArr.pop();
			_localFolder = unescape( thePathArr.join("/") ).replace("|", ":") + "/";
			//trace(_localFolder);
		}
		
		private function createConnection():LocalConnection {
			var theConn:LocalConnection = new LocalConnection();
			theConn.allowDomain("*");
			theConn.allowInsecureDomain("*");
			theConn.client = this;
			return theConn;
		}
		
		private function onStatus(e:StatusEvent):void {
			if (e.level === "error") {
				trace("[AIRFileSaveClient] Are you sure the path is valid AND the AIRFileSave app is running?\nValid? " + _lastURI);
			}
		}
		
		private function resolvePath( pFileName:String ):String {
			var currentLocal:String = _localFolder;
			while (pFileName.indexOf("../")>-1) {
				pFileName = pFileName.substr(3);
				
				var lastSlashIndex:int = currentLocal.lastIndexOf("/", currentLocal.length-2) + 1;
				currentLocal = currentLocal.substr(0, lastSlashIndex );
			}
			_resolvedURI = currentLocal + pFileName;
			return _resolvedURI;
		}
		
		public function open( pFileName:String, pOnLoaded:Function=null, pOnError:Function=null ):AIRFileSaveHandler {
			var handler:AIRFileSaveHandler = new AIRFileSaveHandler(pFileName, this);
			handler.onLoaded = pOnLoaded;
			handler.onError = pOnError;
			handler.load();
			return handler;
		}
		
		public function saveText(pFileName:String, pContent:String):void {
			if (pFileName.indexOf(":") === -1) pFileName = resolvePath(pFileName);
			_lastURI = pFileName;
			_connOutput.send(_connName, "saveText", pFileName, pContent);
		}
		
		public function appendText(pFileName:String, pContent:String):void {
			if (pFileName.indexOf(":") === -1) pFileName = resolvePath(pFileName);
			_lastURI = pFileName;
			_connOutput.send(_connName, "appendText", pFileName, pContent);
		}
		
		public function saveBytes(pFileName:String, pByteArray:ByteArray):void {
			if (pFileName.indexOf(":") === -1) pFileName = resolvePath(pFileName);
			_lastURI = pFileName;
			pByteArray.position = 0;
			_connOutput.send(_connName, "saveBytes", pFileName, pByteArray);
		}
		
		public function appendBytes(pFileName:String, pByteArray:ByteArray):void {
			if (pFileName.indexOf(":") === -1) pFileName = resolvePath(pFileName);
			_lastURI = pFileName;
			pByteArray.position = 0;
			_connOutput.send(_connName, "appendBytes", pFileName, pByteArray);
		}
		
		public function listDirectory( pDir:String, pOnComplete:Function ):void {
			_receiver._onListDirectory = pOnComplete;
			if (pDir.indexOf(":") === -1) pDir = resolvePath(pDir);
			_connOutput.send(_connName, "listDirectory", pDir);
		}
		
		public function createDirectory( pDir:String, pOnComplete:Function ):void {
			_receiver._onCreateDirectory = pOnComplete;
			if (pDir.indexOf(":") === -1) pDir = resolvePath(pDir);
			_connOutput.send(_connName, "createDirectory", pDir);
		}
		
		public function deleteDirectory( pDir:String, pOnComplete:Function ):void {
			_receiver._onDeleteDirectory = pOnComplete;
			if (pDir.indexOf(":") === -1) pDir = resolvePath(pDir);
			_connOutput.send(_connName, "deleteDirectory", pDir);
		}
		
		public function deleteFile( pDir:String, pOnComplete:Function ):void {
			_receiver._onDeleteDirectory = pOnComplete;
			if (pDir.indexOf(":") === -1) pDir = resolvePath(pDir);
			_connOutput.send(_connName, "deleteFile", pDir);
		}
		
		public function startCommand( pCommand:String, pArgs:Array, pOnComplete:Function ):void {
			_receiver._onStartCommand = pOnComplete;
			if (pCommand.indexOf(":") === -1) pCommand = resolvePath(pCommand);
			_connOutput.send(_connName, "startCommand", pCommand, pArgs);
		}
	}
}
import bigp.AIRFileSaveClient;
import flash.net.LocalConnection;

internal class clsAIRClientReceiver {
	public var client:AIRFileSaveClient;
	internal var _connInput:LocalConnection;
	internal var _onListDirectory:Function;
	internal var _onCreateDirectory:Function;
	internal var _onDeleteDirectory:Function;
	internal var _onDeleteFile:Function;
	internal var _onStartCommand:Function;
	
	public function clsAIRClientReceiver(pClient:AIRFileSaveClient) {
		client = pClient;
	}
	
	public function resetCallbacks():void {
		_onListDirectory = null;
		_onCreateDirectory = null;
		_onDeleteDirectory = null;
		_onDeleteFile = null;
		_onStartCommand = null;
	}
	
	public function receiveListDirectory( pFileNames:Array ):void {
		if (_onListDirectory != null) _onListDirectory(pFileNames);
	}
	
	public function receiveCreateDirectory( pFilePath:String ):void {
		if (_onCreateDirectory != null) _onCreateDirectory( pFilePath );
	}
	
	public function receiveDeleteDirectory( pFilePath:String ):void {
		if (_onDeleteDirectory != null) _onDeleteDirectory( pFilePath );
	}
	
	public function receiveDeleteFile( pFilePath:String ):void {
		if (_onDeleteFile != null) _onDeleteFile( pFilePath );
	}
	
	public function receiveStartCommand( pResult:String ):void {
		if (_onStartCommand != null) _onStartCommand( pResult );
	}
}