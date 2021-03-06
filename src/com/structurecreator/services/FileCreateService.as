package com.structurecreator.services
{
	import com.structurecreator.events.FileEvent;
	import com.structurecreator.model.CustomVariableModel;
	import com.structurecreator.model.files.FileTypes;
	import com.structurecreator.services.vo.FileDetailsVO;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import org.robotlegs.mvcs.Actor;
	
	public class FileCreateService extends Actor
	{
		private var _dir:String;
		private var _url:String;
		private var _name:String;
		private var _file_content:String;
		private var _byte_content:ByteArray;
		
		private var _loader:URLStream;
		private var _urlLoader:URLLoader;
		private var _file_ext:String;
		
		[Inject]
		public var customVarsModel:CustomVariableModel;
		
		[Inject]
		public var microsoftX:MicrosoftXFileService;
		
		public function FileCreateService()
		{
		}
		
		/**
		 * Initialise file creation from fileDetailsVO
		 */
		public function init(fileDetailsVO:FileDetailsVO):void
		{
			_dir = fileDetailsVO.dir;
			_url = fileDetailsVO.url;
			
			_name = customVarsModel.updateVariablesInStr(fileDetailsVO.name);
			_file_content = fileDetailsVO.file_content;
			
			_file_ext = (_name.substr(_name.lastIndexOf('.') + 1) as String).toLowerCase();
			
			if (_url == '')
			{
				//Text file from content in XML
				createTextFile();
			}
			else if (FileTypes.NON_TEXT_EXT_ARRAY.indexOf(_file_ext) > -1)
			{
				//Non text based file
				loadByteFile();
			} 
			else
			{
				//Text file from URL
				loadTextFileContent();
			}
		}
		
		/**
		 * Load byte file from URL
		 */
		private function loadByteFile():void
		{
			_loader = new URLStream();
			_byte_content = new ByteArray();
			//_byte_content.endian = Endian.BIG_ENDIAN;
			_loader.addEventListener(Event.COMPLETE, byteFileLoaded);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, byteFileIOError);
			_loader.load(new URLRequest(_url));
		}
		
		/**
		 * Byte File IO Error
		 */
		private function byteFileIOError(e:IOErrorEvent):void 
		{
			trace("CANNOT LOAD " + _name);
		}
		
		/**
		 * On byte file loaded
		 */
		private function byteFileLoaded(e:Event):void 
		{
			_loader.removeEventListener(Event.COMPLETE, byteFileLoaded);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, byteFileIOError);
			trace("File contents LOADED for " + _name);
			
			_loader.readBytes(_byte_content, 0, _loader.bytesAvailable);
			createByteFile();
		}
		
		/**
		 * Create byte file
		 */
		private function createByteFile():void
		{
			var file:File = new File();
			file.url = _dir;
			file = file.resolvePath(_name);
			
			trace('the file ext : ' + _file_ext);
			switch (_file_ext) 
			{
				//If file is a Microsoft office doc.
				case 'docx':
				case 'pptx':
				case 'xlsx':
					//var mx:MicrosoftXModel = new MicrosoftXModel(file, _byte_content);
					microsoftX.init(file, _byte_content);
					//mx.addEventListener(FileEvent.FILE_CREATED, mx_fileCreated);
					break;
				//All other byte files
				default:
					var fs:FileStream = new FileStream();
					fs.open(file, FileMode.WRITE);
					fs.writeBytes(_byte_content);
					fs.close();
					
					complete();
					break;
			}
		}
		
		/*private function mx_fileCreated(e:FileEvent):void 
		{
			//(e.currentTarget as MicrosoftX).removeEventListener(FileEvent.FILE_CREATED, mx_fileCreated);
			complete();
		}*/
		
		/**
		 * Text Based File Load
		 */
		private function loadTextFileContent():void
		{
			trace("Load file contents for " + _name);
			_urlLoader = new URLLoader();
			_urlLoader.addEventListener(Event.COMPLETE, textFileLoaded);
			_urlLoader.addEventListener(ProgressEvent.PROGRESS, urlLoader_progress);
			_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			_urlLoader.load(new URLRequest(_url));
		}
		
		/**
		 * Loader Progress
		 */
		private function urlLoader_progress(e:ProgressEvent):void 
		{
			trace(e.bytesLoaded / e.bytesTotal);
		}
		
		/**
		 * Load IO Error
		 */
		private function onIOError(e:IOErrorEvent):void 
		{
			trace("Error loading text file");
			//TODO add to log file
			complete();
		}
		
		/**
		 * Text based file loaded
		 */
		private function textFileLoaded(e:Event):void
		{
			//_urlLoader.removeEventListener(Event.COMPLETE, textFileLoaded);
			//_urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			trace("File contents LOADED for " + _name);
			_file_content = e.currentTarget.data as String;
			createTextFile();
		}
		
		/**
		 * Create text based file
		 */
		private function createTextFile():void
		{
			_file_content = customVarsModel.updateVariablesInStr(_file_content);
			
			var file:File = new File();
			file.url = _dir;
			file = file.resolvePath(_name);
			
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.WRITE);
			//fs.writeUTFBytes(CustomVariables.getInstance().updateVars(_file_content));
			fs.writeUTFBytes(_file_content);
			fs.close();
			
			complete();
		}
		
		/**
		 * On Creation complete
		 */
		private function complete():void 
		{
			trace(_name, 'created');
			_loader = null;
			_urlLoader = null;
			
			//Timer to add a slight delay for files created from xml text content
			var t:Timer = new Timer(100,1);
			t.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
			t.start();
			//dispatchEvent(new FileEvent(FileEvent.FILE_CREATED));
		}
		
		/**
		 * Dispatch event that file has been created
		 */
		protected function onTimerComplete(event:TimerEvent):void
		{
			eventDispatcher.dispatchEvent(new FileEvent(FileEvent.FILE_CREATED));
		}
	}
}