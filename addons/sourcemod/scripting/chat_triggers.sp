#include <sourcemod>
#include <cstrike>

/** new syntax & semicolon **/
#pragma semicolon 1
#pragma newdecls required

ArrayList g_NewTriggers;
ArrayList g_ReplaceTriggers;

ConVar g_SilentTriggerCVar;
ConVar g_SilentModeEnabledCVar;

public void OnPluginStart() {
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("ERROR: This plugin is designed only for CS:GO.");
	}

	g_SilentTriggerCVar = CreateConVar("sm_triggers_silent_trigger", "/", "If you changed your silent trigger, also change it here");
	g_SilentModeEnabledCVar = CreateConVar("sm_triggers_silent_mode", "1", "Wether a recognized command should be displayed");

	g_NewTriggers = new ArrayList(32);
	g_ReplaceTriggers = new ArrayList(32);

	// Load Triggers from configs/ffa/chat_triggers.cfg
	LoadChatTriggers();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] arg) {
	if (IsPlayer(client)) {
		char SilentTrigger[8];
		GetConVarString(g_SilentTriggerCVar, SilentTrigger, sizeof(SilentTrigger));
		int index = g_NewTriggers.FindString(arg);
		char oldTrigger[16];
		if(index == -1) return Plugin_Continue;

		g_ReplaceTriggers.GetString(index, oldTrigger, sizeof(oldTrigger));
		FakeClientCommandEx(client, "say %s%s", SilentTrigger, oldTrigger);
		if(GetConVarBool(g_SilentModeEnabledCVar)) return Plugin_Handled;
		else return Plugin_Continue;
	}
	return Plugin_Continue;
}

public void LoadChatTriggers() {
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/chat_triggers+.cfg");
	KeyValues kv = new KeyValues("Chat Triggers");
	if (!FileToKeyValues(kv, path))
		SetFailState("The configuration file could not be read.");

	char key[25];
	char value[25];
	/** Reading KeyValues **/
	g_NewTriggers.Clear();
	g_ReplaceTriggers.Clear();

	if (kv.GotoFirstSubKey(false)) {
		do {
			kv.GetSectionName(key, sizeof(key));
			kv.GetString(NULL_STRING, value, sizeof(value));
			g_NewTriggers.PushString(key);
			g_ReplaceTriggers.PushString(value);
		} while (kv.GotoNextKey(false));
	}
	kv.GoBack();
	kv.GoBack();

	delete kv;
}

public bool IsPlayer(int client) {
	return 	client > 0 && client <= MaxClients &&
			IsClientConnected(client) && IsClientInGame(client) &&
			!IsFakeClient(client);
}