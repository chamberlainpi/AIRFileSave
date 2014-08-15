package bigp {
	import flash.display.LoaderInfo;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;

	/**
	 * ...
	 * @author Pierre Chamberlain
	 */
	public class AIRFileSaveClient {
		private static const _CONNECTION_INIT_FRAMES:int = 5;
		private static const _CONNECTION_INIT_RETRY:int = 10;
		private static const _CONNECTION_RECONNECT:int = 25;
		private static var _CONNECTION_CHECK_INTERVAL:int = -1;
		private static var _CONNECTION_NAME:String = "connection";
		
		private var _loaderInfo:LoaderInfo;
		private var _connOutput:LocalConnection;
		private var _connectionName:String;
		private var _enterframeCounter:int;
		private var _enterframeFunc:Function;
		private var _localFolder:String;
		private var _lastURI:String;
		private var _resolvedURI:String;
		private var _receiver:clsAIRClientReceiver;
		
		internal var _isConnected:Boolean = false;
		
		public var whenOnConnection:Function;
		public var isTraceEnabled:Boolean = true;
		public var isAutoReconnect:Boolean = true;
		
		public function AIRFileSaveClient(pSecureLoaderInfo:LoaderInfo = null) {
			//Resolve the local folder:
			_loaderInfo = pSecureLoaderInfo || LoaderInfo.getLoaderInfoByDefinition(ApplicationDomain.currentDomain);
			var thePath:String = _loaderInfo.url;
			var thePathArr:Array = thePath.replace("file:///", "").split("/");
			thePathArr.pop();
			_localFolder = unescape( thePathArr.join("/") ).replace("|", ":") + "/";
			_connectionName = "app#AIRFileSave:" + _CONNECTION_NAME;
			//Enter a loop to start the connection setup:
			beginConnectionSetup();
		}
		
		private function beginConnectionSetup():void 
		{
			if (_loaderInfo == null) throw new Error("LoaderInfo is not assigned.");
			if (_loaderInfo.content == null) throw new Error("LoaderInfo.content is not assigned / ready.");
			
			_enterframeCounter = _CONNECTION_INIT_FRAMES;
			_enterframeFunc = tryConnectionOutput;
			_loaderInfo.content.addEventListener(Event.ENTER_FRAME, tryConnections);
		}
		
		private function tryConnections(e:Event):void 
		{
			if ((--_enterframeCounter) > 0) return;
			
			if (_enterframeFunc != null) {
				_enterframeFunc();
			} else {
				if (isTraceEnabled) trace("Stopping try-enter-frame loop for connection setup.");
				IEventDispatcher(e.target).removeEventListener(e.type, tryConnections);
			}
		}
		
		private function tryConnectionOutput():void 
		{
			try {
				if (isTraceEnabled) trace("Attempt Connection Output setup...");
				_connOutput = createConnection(this);
				_connOutput.addEventListener(StatusEvent.STATUS, onStatus);
				
				_enterframeCounter = _CONNECTION_INIT_FRAMES;
				_enterframeFunc = tryConnectionInput;
			} catch (err:Error) {
				if (isTraceEnabled) trace("Connection Output couldn't be instantiated.");
				_enterframeCounter = _CONNECTION_INIT_RETRY;
			}
		}
		
		private function tryConnectionInput():void 
		{
			if (_receiver == null) {
				_receiver = new clsAIRClientReceiver(this);
				_receiver._onCheckConnect = signalOfConnectionOK;
				_receiver._onMaintainConnect = signalOfConnectionOK;
			}
				
			try {
				if (isTraceEnabled) trace("Attempt Connection Input setup...");
				
				if (_receiver._connInput) _receiver._connInput.close();
				_receiver._connInput = createConnection(_receiver);
				_receiver._connInput.connect(_CONNECTION_NAME);
				
				_enterframeCounter = _CONNECTION_INIT_FRAMES;
				_enterframeFunc = tryConnectionHandshake;
			} catch (err:Error) {
				if (isTraceEnabled) trace("Connection Input (receiver) couldn't be instantiated / connected:\n" + err.message + "\n" + err.getStackTrace());
				_enterframeCounter = _CONNECTION_RECONNECT; // _CONNECTION_INIT_RETRY;
			}
		}
		
		private function tryConnectionHandshake():void 
		{
			try {
				if (isTraceEnabled) trace("Attempt Connection Handshake (checks communication)...");
				_connOutput.send(_connectionName, _lastURI = "checkConnection");
				
				if (isTraceEnabled && isAutoReconnect) {
					trace("Will try to maintain connection. (checks every " + numFramesRetry + " frames).");
				}
				
				_enterframeFunc = tryMaintainConnection;
			} catch (err:Error) {
				if (isTraceEnabled) trace("Connection Handshake (checkConnection) NOT sent successfully.");
				_enterframeCounter = _CONNECTION_INIT_RETRY;
			}
		}
		
		private function tryMaintainConnection():void 
		{
			try {
				if (isTraceEnabled) trace("Attempt MaintainConnection (checks communication)...");
				
				_connOutput.send(_connectionName, _lastURI = "maintainConnection");
				
				if (_CONNECTION_CHECK_INTERVAL == -1) _enterframeCounter = numFramesRetry;
				else _enterframeCounter = _CONNECTION_CHECK_INTERVAL;
			} catch (err:Error) {
				if (isTraceEnabled) trace("Lost connection while maintaining it (checks communication)...");
				
				signalOfConnectionFAIL();
				
				if (isAutoReconnect) {
					_enterframeFunc = tryConnectionInput;
				}
			}
		}
		
		private function signalOfConnectionOK():void {
			if (_isConnected) return;
			_isConnected = true;
			if(whenOnConnection!=null) whenOnConnection(true);
		}
		
		private function signalOfConnectionFAIL():void {
			if (!_isConnected) return;
			if (isTraceEnabled) {
				trace("[AIRFileSaveClient] Are you sure the path is valid AND the AIRFileSave app is running?\n" +
					"--Is the command valid? '" + _lastURI + "'");
			}
			_isConnected = false;
			if(whenOnConnection!=null) whenOnConnection(false);
		}
		
		private function createConnection(pClient:Object):LocalConnection {
			var theConn:LocalConnection = new LocalConnection();
			theConn.allowDomain("*");
			theConn.allowInsecureDomain("*");
			theConn.client = pClient;
			return theConn;
		}
		
		private function onStatus(e:StatusEvent):void {
			if (e.level === "error") {
				signalOfConnectionFAIL();
				_enterframeFunc = tryConnectionInput;
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
			_connOutput.send(_connectionName, "saveText", pFileName, pContent);
		}
		
		public function appendText(pFileName:String, pContent:String):void {
			if (pFileName.indexOf(":") === -1) pFileName = resolvePath(pFileName);
			_lastURI = pFileName;
			_connOutput.send(_connectionName, "appendText", pFileName, pContent);
		}
		
		public function saveBytes(pFileName:String, pByteArray:ByteArray):void {
			if (pFileName.indexOf(":") === -1) pFileName = resolvePath(pFileName);
			_lastURI = pFileName;
			pByteArray.position = 0;
			_connOutput.send(_connectionName, "saveBytes", pFileName, pByteArray);
		}
		
		public function appendBytes(pFileName:String, pByteArray:ByteArray):void {
			if (pFileName.indexOf(":") === -1) pFileName = resolvePath(pFileName);
			_lastURI = pFileName;
			pByteArray.position = 0;
			_connOutput.send(_connectionName, "appendBytes", pFileName, pByteArray);
		}
		
		public function listDirectory( pDir:String, pOnComplete:Function ):void {
			_receiver._onListDirectory = pOnComplete;
			if (pDir.indexOf(":") === -1) pDir = resolvePath(pDir);
			_connOutput.send(_connectionName, "listDirectory", pDir);
		}
		
		public function createDirectory( pDir:String, pOnComplete:Function ):void {
			_receiver._onCreateDirectory = pOnComplete;
			if (pDir.indexOf(":") === -1) pDir = resolvePath(pDir);
			_connOutput.send(_connectionName, "createDirectory", pDir);
		}
		
		public function deleteDirectory( pDir:String, pOnComplete:Function ):void {
			_receiver._onDeleteDirectory = pOnComplete;
			if (pDir.indexOf(":") === -1) pDir = resolvePath(pDir);
			_connOutput.send(_connectionName, "deleteDirectory", pDir);
		}
		
		public function deleteFile( pDir:String, pOnComplete:Function ):void {
			_receiver._onDeleteDirectory = pOnComplete;
			if (pDir.indexOf(":") === -1) pDir = resolvePath(pDir);
			_connOutput.send(_connectionName, "deleteFile", pDir);
		}
		
		public function startCommand( pCommand:String, pArgs:Array, pOnComplete:Function ):void {
			_receiver._onStartCommand = pOnComplete;
			if (pCommand.indexOf(":") === -1) pCommand = resolvePath(pCommand);
			_connOutput.send(_connectionName, "startCommand", pCommand, pArgs);
		}
		
		public function get isConnected():Boolean { return _isConnected; }
		private function get numFramesRetry():int { return _loaderInfo.content.stage.frameRate * 2; }
	}
}
import bigp.AIRFileSaveClient;
import flash.net.LocalConnection;

internal class clsAIRClientReceiver {
	public var client:AIRFileSaveClient;
	internal var _connInput:LocalConnection;
	internal var _onCheckConnect:Function;
	internal var _onMaintainConnect:Function;
	internal var _onListDirectory:Function;
	internal var _onCreateDirectory:Function;
	internal var _onDeleteDirectory:Function;
	internal var _onDeleteFile:Function;
	internal var _onStartCommand:Function;
	
	public function clsAIRClientReceiver(pClient:AIRFileSaveClient) {
		client = pClient;
	}
	
	public function resetCallbacks():void {
		_onCheckConnect = null;
		_onMaintainConnect = null;
		_onListDirectory = null;
		_onCreateDirectory = null;
		_onDeleteDirectory = null;
		_onDeleteFile = null;
		_onStartCommand = null;
	}
	
	public function receiveCheckConnection():void {
		if(_onCheckConnect != null) _onCheckConnect();
	}
	
	public function receiveMaintainConnection():void {
		if (_onMaintainConnect != null) _onMaintainConnect;
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