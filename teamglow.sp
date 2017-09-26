/*
 * TeamGlow.
 * by: shanapu
 * https://github.com/shanapu/
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

/******************************************************************************
                   STARTUP
******************************************************************************/

// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <mystocks>
#include <CustomPlayerSkins>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

// Console Variables
ConVar gc_iGlowMode;

ConVar gc_iCTColorRed;
ConVar gc_iCTColorGreen;
ConVar gc_iCTColorBlue;
ConVar gc_iCTColorAlpha;

ConVar gc_iTColorRed;
ConVar gc_iTColorGreen;
ConVar gc_iTColorBlue;
ConVar gc_iTColorAlpha;

// Info
public Plugin myinfo = {
	name = "Team Glow",
	author = "shanapu",
	description = "Glow effect for your teammates",
	version = "2.0",
	url = "https://github.com/shanapu/"
};

// Start
public void OnPluginStart()
{
	AutoExecConfig(true,"TeamGlow");

	gc_iGlowMode = CreateConVar("sm_glow_mode", "1", "1 - contours with wallhack, 2 - glow effect without wallhack", _, true, 1.0, true, 2.0);

	gc_iCTColorRed = CreateConVar("sm_glow_color_ct_red", "0", "What color for Glow? (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iCTColorGreen = CreateConVar("sm_glow_color_ct_green", "250", "What color for Glow? (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iCTColorBlue = CreateConVar("sm_glow_color_ct_blue", "250", "What color for Glow? (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_iCTColorAlpha = CreateConVar("sm_glow_color_ct_alpha", "250", "How bright? alpha value", _, true, 0.0, true, 255.0);

	gc_iTColorRed = CreateConVar("sm_glow_color_t_red", "0", "What color for Glow? (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iTColorGreen = CreateConVar("sm_glow_color_t_green", "250", "What color for Glow? (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iTColorBlue = CreateConVar("sm_glow_color_t_blue", "250", "What color for Glow? (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_iTColorAlpha = CreateConVar("sm_glow_color_t_alpha", "250", "How bright? alpha value", _, true, 0.0, true, 255.0);

	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
}

public void Event_PlayerSpawn(Event event, char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	
	CreateTimer(1.1, Timer_Delay, userid);
}

public Action Timer_Delay(Handle timer, int userid)
{
	SetupGlowSkin(GetClientOfUserId(userid));
}

public void Event_PlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	UnhookGlow(client);
}

public void Event_RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		UnhookGlow(i);
	}
}

public void OnClientDisconnect(int client)
{
	UnhookGlow(client);
}

// Perpare client for glow
void SetupGlowSkin(int client)
{
	if (!IsValidClient(client, true, true))
	{
		return;
	}

	char sModel[PLATFORM_MAX_PATH];
	GetClientModel(client, sModel, sizeof(sModel));

	int iSkin = CPS_SetSkin(client, sModel, CPS_RENDER);
	if (iSkin == -1)
	{
		return;
	}

	if (SDKHookEx(iSkin, SDKHook_SetTransmit, OnSetTransmit_GlowSkin))
	{
		GlowSkin(iSkin, client);
	}
}

// set client glow
void GlowSkin(int iSkin, int client)
{
	int iOffset;

	if ((iOffset = GetEntSendPropOffs(iSkin, "m_clrGlow")) == -1)
		return;

	SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", true, true);
	if (gc_iGlowMode.IntValue == 1) SetEntProp(iSkin, Prop_Send, "m_nGlowStyle", 0);
	if (gc_iGlowMode.IntValue == 2) SetEntProp(iSkin, Prop_Send, "m_nGlowStyle", 1);
	SetEntPropFloat(iSkin, Prop_Send, "m_flGlowMaxDist", 10000000.0);

	int iRed, iGreen, iBlue, iAlpha;

	if (GetClientTeam(client) == CS_TEAM_CT)
	{
		iRed = gc_iCTColorRed.IntValue;
		iGreen = gc_iCTColorGreen.IntValue;
		iBlue = gc_iCTColorBlue.IntValue;
		iAlpha = gc_iCTColorAlpha.IntValue;
	}
	else if (GetClientTeam(client) == CS_TEAM_T)
	{
		iRed = gc_iTColorRed.IntValue;
		iGreen = gc_iTColorGreen.IntValue;
		iBlue = gc_iTColorBlue.IntValue;
		iAlpha = gc_iTColorAlpha.IntValue;
	}

	SetEntData(iSkin, iOffset, iRed, _, true);
	SetEntData(iSkin, iOffset + 1, iGreen, _, true);
	SetEntData(iSkin, iOffset + 2, iBlue, _, true);
	SetEntData(iSkin, iOffset + 3, iAlpha, _, true);
}

// Who can see the glow if vaild
public Action OnSetTransmit_GlowSkin(int iSkin, int client)
{
	if (!IsPlayerAlive(client))
		return Plugin_Handled;

	for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
	{
		if (!CPS_HasSkin(i))
		{
			continue;
		}

		if (EntRefToEntIndex(CPS_GetSkin(i)) != iSkin)
		{
			continue;
		}

		if (GetClientTeam(i) != GetClientTeam(client))
		{
			continue;
		}

		return Plugin_Continue;
	}

	return Plugin_Handled;
}

// remove glow
void UnhookGlow(int client)
{
	if (IsValidClient(client, true, true))
	{
		int iSkin = CPS_GetSkin(client);
		if (iSkin != INVALID_ENT_REFERENCE)
		{
			SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", false, true);
			SDKUnhook(iSkin, SDKHook_SetTransmit, OnSetTransmit_GlowSkin);
		}
	}
}