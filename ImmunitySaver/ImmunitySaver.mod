<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="ImmunitySaver" version="1.00" date="12/29/2023" >
		<Author name="Emissary" email="" />
		<Description text="ImmunitySaver" />
		<VersionSettings gameVersion="1.4.8" windowsVersion="1.0" savedVariablesVersion="1.0" />

		<Dependencies>
			<Dependency name="EA_ActionBars" />
			<Dependency name="LibSlash" />
		</Dependencies>
			
		<Files>
			<File name="libs\LibStub.lua" />
			<File name="libs\LibGUI.lua" />
			<File name="libs\LibConfig.lua" />		
			<File name="ImmunitySaver.lua" />			
			<File name="ImmunitySaver_Config.lua" />						
		</Files>

		<SavedVariables>
			<SavedVariable name="ImmunitySaver.Settings" />
		</SavedVariables>

		<OnInitialize>
			<CallFunction name="ImmunitySaver.Initialize" />
		</OnInitialize>

		<OnUpdate>
			<CallFunction name="ImmunitySaver.OnUpdate" />
		</OnUpdate>

		<OnShutdown>
			<CallFunction name="ImmunitySaver.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
