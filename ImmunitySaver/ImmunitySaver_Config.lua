LibConfig = LibStub("LibConfig")

ImmunitySaver_Config = {}

local GUI

function ImmunitySaver_Config.Slash(input)
	if (not GUI) then
		-- parameters: title text, settings table, callback-function
		-- note that you need to have a settings table!
		GUI = LibConfig("ImmunitySaver v" .. tostring(ImmunitySaver.Settings.Version), ImmunitySaver.Settings, true, ImmunitySaver_Config.SettingsChanged)
		
		GUI:AddTab("Info")
		local infoText
		infoText = GUI("label", "ImmunitySaver can set a check for abilities that will be ineffective if the target is immune or when the target")
		infoText.label:Font("font_default_text_small")
		infoText.label:Align("left")

		infoText = GUI("label", "The check will be indicated with these symbols:")
		infoText.label:Font("font_default_text_small")
		infoText.label:Align("left")

		infoText = GUI("label", "<icon05007> - Immovable")
		infoText.label:Font("font_default_text_small")
		infoText.label:Align("left")

		infoText = GUI("label", "<icon05006> - Unstoppable")
		infoText.label:Font("font_default_text_small")
		infoText.label:Align("left")

		infoText = GUI("label", "When the ability's check is triggered the ability will be disabled (greyed out) on the hotbar.")
		infoText.label:Font("font_default_text_small")
		infoText.label:Align("left")


		infoText = GUI("label", "To toggle the check on an ability SHIFT-LEFT CLICK the ability on your hotbar.")
		infoText.label:Font("font_default_text_small")
		infoText.label:Align("left")

		infoText = GUI("label", "By default targeted abilities that Knock-down, Punt, Stagger, Silence or Disarm are configured accordingly.")
		infoText.label:Font("font_default_text_small")
		infoText.label:Align("left")


		GUI:AddTab("Settings")
		GUI("checkbox", "Enabled", "Enabled")
		GUI("checkbox", "Show Symbols", "Symbols")
		GUI("checkbox", "Show Combat Error messages", "ErrorMessages")

	end
	GUI:Show()
end

function ImmunitySaver_Config.SettingsChanged()
	GUI:Hide()
	ImmunitySaver.UpdateSettings()
end