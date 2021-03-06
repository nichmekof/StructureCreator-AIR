package com.structurecreator
{
	import com.structurecreator.controller.DatabaseCommand;
	import com.structurecreator.controller.FileCommand;
	import com.structurecreator.controller.ProfileChangeCommand;
	import com.structurecreator.controller.ProfileCommand;
	import com.structurecreator.events.CustomVarsEvent;
	import com.structurecreator.events.FileEvent;
	import com.structurecreator.events.ProfileEvent;
	import com.structurecreator.events.SchemaEvent;
	import com.structurecreator.events.StructureCreatorEvent;
	import com.structurecreator.model.CustomVariableModel;
	import com.structurecreator.model.ProjectFolderModel;
	import com.structurecreator.model.SchemaModel;
	import com.structurecreator.model.StructureCreatorModel;
	import com.structurecreator.model.schemas.XMLSchema;
	import com.structurecreator.services.DatabaseService;
	import com.structurecreator.services.FileCreateService;
	import com.structurecreator.services.MicrosoftXFileService;
	import com.structurecreator.services.ProfileService;
	import com.structurecreator.view.CreateButtonMediator;
	import com.structurecreator.view.CreateButtonView;
	import com.structurecreator.view.CustomVariablesMediator;
	import com.structurecreator.view.CustomVariablesView;
	import com.structurecreator.view.ProfileButtonsMediator;
	import com.structurecreator.view.ProfileButtonsView;
	import com.structurecreator.view.ProfileSelectMediator;
	import com.structurecreator.view.ProfileSelectView;
	import com.structurecreator.view.ProjectFolderMediator;
	import com.structurecreator.view.ProjectFolderView;
	import com.structurecreator.view.SchemaSelectMediator;
	import com.structurecreator.view.SchemaSelectView;
	import com.structurecreator.view.customvars.CustomVariableBarMediator;
	import com.structurecreator.view.customvars.CustomVariableBarView;
	import com.structurecreator.view.editprofile.EditProfileMediator;
	import com.structurecreator.view.editprofile.EditProfileView;
	import com.structurecreator.view.saveprofile.SaveProfileWindow;
	import com.structurecreator.view.saveprofile.SaveProfileWindowMediator;
	
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	
	import mx.controls.Alert;
	import mx.core.IFlexDisplayObject;
	import mx.managers.PopUpManager;
	
	import org.robotlegs.base.MediatorMap;
	import org.robotlegs.mvcs.Context;
	
	public class MainContext extends Context
	{

		private var _saveProfileWindow:SaveProfileWindow;
		
		public function MainContext()
		{
		}
		
		override public function startup():void
		{
			trace("App Started");
			/* Setup models */
			injector.mapSingleton(ProjectFolderModel);
			injector.mapSingleton(SchemaModel);
			injector.mapSingleton(XMLSchema);
			injector.mapSingleton(StructureCreatorModel);
			injector.mapSingleton(CustomVariableModel);
			injector.mapSingleton(DatabaseService);
			injector.mapSingleton(ProfileService);
			
			/* Setup File Creation Services */
			injector.mapClass(FileCreateService, FileCreateService);
			//var fcs:FileCreateService = injector.getInstance(FileCreateService);
			//injector.mapValue(FileCreateService, fcs);
			injector.mapClass(MicrosoftXFileService, MicrosoftXFileService);
			
			/* Map views to their mediators */
			mediatorMap.mapView(ProfileSelectView, ProfileSelectMediator);
			mediatorMap.mapView(ProjectFolderView, ProjectFolderMediator);
			mediatorMap.mapView(SchemaSelectView, SchemaSelectMediator);
			mediatorMap.mapView(CreateButtonView, CreateButtonMediator);
			mediatorMap.mapView(CustomVariablesView, CustomVariablesMediator);
			mediatorMap.mapView(CustomVariableBarView, CustomVariableBarMediator);
			mediatorMap.mapView(ProfileButtonsView, ProfileButtonsMediator);
			mediatorMap.mapView(SaveProfileWindow, SaveProfileWindowMediator);
			mediatorMap.mapView(EditProfileView, EditProfileMediator);
			
			/* Commands for file creation */
			commandMap.mapEvent(FileEvent.START_CREATION, FileCommand, FileEvent);
			commandMap.mapEvent(StructureCreatorEvent.APP_STARTED, DatabaseCommand, StructureCreatorEvent);
			commandMap.mapEvent(ProfileEvent.SAVE_PROFILE, ProfileCommand, ProfileEvent);
			commandMap.mapEvent(ProfileEvent.PROFILE_SELECTED, ProfileChangeCommand, ProfileEvent);
			
			/* Listen for creation complete event */
			eventDispatcher.addEventListener(StructureCreatorEvent.CREATION_COMPLETE, onCreationComplete);
			eventDispatcher.dispatchEvent(new StructureCreatorEvent(StructureCreatorEvent.APP_STARTED));
			eventDispatcher.addEventListener(ProfileEvent.OPEN_SAVE_WINDOW, onOpenSaveProfile);
			eventDispatcher.addEventListener(ProfileEvent.SAVE_PROFILE, onSaveProfile);
			eventDispatcher.addEventListener(CustomVarsEvent.CANNOT_ADD_VAR, onCannotAddVar);
			eventDispatcher.addEventListener(SchemaEvent.CREATE_NEW_SCHEMA, onCreateNewSchema);
			eventDispatcher.addEventListener(ProfileEvent.EDIT_PROFILES, onProfileEdit);
			
			super.startup();
		}
		
		private function onProfileEdit(e:ProfileEvent):void
		{
			// TODO Auto Generated method stub
			var editProfile:EditProfileView = new EditProfileView();
			editProfile.open();
			
			mediatorMap.createMediator(editProfile);
		}
		
		private function onCreateNewSchema(e:SchemaEvent):void
		{
			trace("Open schema creator window");
			var schemaWindow:SchemaCreator = new SchemaCreator();
			schemaWindow.open();
			//var 
		}
		
		private function onCannotAddVar(e:CustomVarsEvent):void
		{
			Alert.show("You can't add a new custom variable until the previous one is filled in", "Can't add Custom Variable");
		}
		
		/**
		 * Opens Save Profile window
		 */
		private function onOpenSaveProfile(e:ProfileEvent):void
		{
			_saveProfileWindow = new SaveProfileWindow();
			
			PopUpManager.addPopUp(_saveProfileWindow, _contextView, true);
			PopUpManager.centerPopUp(_saveProfileWindow);
			
			mediatorMap.createMediator(_saveProfileWindow);
		}
		
		/**
		 * When profile is saved Close the window
		 */
		private function onSaveProfile(e:ProfileEvent):void
		{
			PopUpManager.removePopUp(_saveProfileWindow);
		}
		
		/**
		 * On Creation Complete
		 * Show that all files have been created
		 */
		private function onCreationComplete(event:Event):void
		{
			Alert.show("All the files and folders have been created.", "All Done!");
		}
	}
}