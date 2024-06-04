#include <a_samp>
#include "streamer"

native NPC_Create(const name[]);
native NPC_Destroy(npcid);
native NPC_IsValid(npcid);
native NPC_Spawn(npcid);
native NPC_SetPos(npcid, Float:x, Float:y, Float:z);
native NPC_GetPos(npcid, &Float:x, &Float:y, &Float:z);
native NPC_SetRot(npcid, Float:x, Float:y, Float:z);
native NPC_GetRot(npcid, &Float:x, &Float:y, &Float:z);
native NPC_SetVirtualWorld(npcid, vw);
native NPC_GetVirtualWorld(npcid, &vw);
native NPC_Move(npcid, Float:x, Float:y, Float:z, moveType);
native NPC_StopMove(npcid);

forward OnNPCFinishMove(npcid);
forward OnNPCCreate(npcid);
forward OnNPCDestroy(npcid);

new PlayeridToWNPCid[2048];
new SelectedPlayerid[MAX_PLAYERS];


enum walknpcInfo
{
    walknpc_BDID,//stupid export
    walknpc_Valid,
	walknpc_Name[MAX_PLAYER_NAME],
	walknpc_Skin,
	walknpc_StartNode,//-1
	walknpc_StartTime,//-1
	walknpc_EndTime,//-1
	walknpc_ID,//не сохранять
	walknpc_NextNode,//не сохранять
	walknpc_OldNode,//не сохранять
	walknpc_Nodes,//не сохранять
	walknpc_Created,//не сохранять
    walknpc_PlayerID//dont save
	//walknpc_Timer//не сохранять
}
//new WalkNPC[MAX_WALKNPC][walknpcInfo]


enum walknodeinfo
{
    walknode_BDID,//stupid export
    walknodeValid,
	Float:walknodeX,
	Float:walknodeY,
	Float:walknodeZ,
	walkNodeGroupID,//-1
	walkNodeGroupName[32],
	walknextnode0,//0
	walknextnode1,//0
	walknextnode2,//0
	walknextnode3,//0
	walknodeshowed,//dontsave
	Text3D:walknodetext,//dontsave
}

#include "wnpcmisc.inc"
//new WalkNodeInfo[MAX_WALKNODE][walknodeinfo]
new WNPCFollowTimer[sizeof(WalkNPC)];
new Float:WalkNPCPosX[sizeof(WalkNPC)];
new Float:WalkNPCPosY[sizeof(WalkNPC)];
new Float:WalkNPCPosZ[sizeof(WalkNPC)];
main()
{
    print("\n----------------------------------");
    print("  Walk NPC Script\n");
    print("----------------------------------\n");
}

public OnGameModeInit()
{
    printf("SSSSSS");
    SetTimer("WNPCInit", 1000,0);
    return 1;
}
public OnGameModeExit()
{
    WNPCPrint();
    return 1;
}

stock WNPCPrint()
{
    for(new i; i<sizeof(WalkNPC); i++)
    {
        if(WalkNPC[i][walknpc_Nodes]<3)
            printf("WNPC %d, nodes after start server %d",WalkNPC[i][walknpc_Nodes]);
    }
    return 1;
}

public OnNPCCreate(npcid)
{
    SetTimerEx("WNPCSpawn", 1000, 0, "d", npcid);
    return 1;
}
forward WNPCSpawn(npcid);
public WNPCSpawn(npcid)
{
    WalkNPC[PlayeridToWNPCid[npcid]][walknpc_PlayerID]=INVALID_PLAYER_ID;
    NPC_Spawn(npcid);
    SetPlayerSkin(npcid,WalkNPC[PlayeridToWNPCid[npcid]][walknpc_Skin]);
    SetTimerEx("WalkNPCStartMove", 100, 0, "d", PlayeridToWNPCid[npcid]);
    printf("NPC ID %d WNPC %d has connected", npcid, PlayeridToWNPCid[npcid]);
    return 1;
}

forward WalkNPCStartMove(i);
public WalkNPCStartMove(i)
{
    WalkNPC[i][walknpc_NextNode]=WalkNPC[i][walknpc_StartNode];
    WalkNPC[i][walknpc_OldNode]=WalkNPC[i][walknpc_StartNode];
    new thisnodeid=WalkNPC[i][walknpc_OldNode];
	NPC_SetPos(WalkNPC[i][walknpc_ID],WalkNodeInfo[thisnodeid][walknodeX],WalkNodeInfo[thisnodeid][walknodeY],WalkNodeInfo[thisnodeid][walknodeZ]);
    WNPCNextNode(i);
    //SetTimerEx("WNPCCheckPos", 100, 1, "d", i);
    printf("wnpc %d, nodeid %d walk started",i,thisnodeid);
	return 1;
}

public OnNPCDestroy(npcid)
{
    printf("NPC ID %d has disconnected", npcid);
    return 1;
}



public OnPlayerConnect(playerid)
{
    if(NPC_IsValid(playerid))
        return 1;
    SendClientMessage(playerid,COLOR_WHITE,"cmds: /car /gotols /gotofk /create /destroy /check /start /stop /restart /show /hide");
    SendClientMessage(playerid,COLOR_WHITE,"press Y near any walking NPC");
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    printf("Player disconnected: %d", playerid);
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    printf("OnPlayerDeath %i, %i, %i", playerid, killerid, reason);
    return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
    printf("OnPlayerGiveDamage %i, %i, %f, %i, %i", playerid, damagedid, Float:amount, weaponid, bodypart);
    return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
    printf("OnPlayerTakeDamage %i, %i, %f, %i, %i", playerid, issuerid, Float:amount, weaponid, bodypart);
    return 1;
}
forward WNPCInit();
public WNPCInit()
{
    SetTimerEx("WNPCreate", 10, 0, "d", 0);
    return sizeof(WalkNPC);
    /*new b;
    for(new i; i<sizeof(WalkNPC); i++)
    {
        if(WalkNPC[i][walknpc_Created]==0)
        {
            SetTimerEx("WNPCreate", 10, 0, "d", i);
            b++;
        }
    }
    return b;*/
}
forward WNPCreate(i);
public WNPCreate(i)
{
    if(WalkNPC[i][walknpc_Created]==0)
    {
        WalkNPC[i][walknpc_ID]=NPC_Create(WalkNPC[i][walknpc_Name]);
        PlayeridToWNPCid[WalkNPC[i][walknpc_ID]]=i;
        printf("WNPC %d created, NPCID %d, playertownpc %d ",i,WalkNPC[i][walknpc_ID], PlayeridToWNPCid[WalkNPC[i][walknpc_ID]]);
        WalkNPCPosX[i]=WalkNodeInfo[WalkNPC[i][walknpc_StartNode]][walknodeX];
        WalkNPCPosY[i]=WalkNodeInfo[WalkNPC[i][walknpc_StartNode]][walknodeY];
        WalkNPCPosZ[i]=WalkNodeInfo[WalkNPC[i][walknpc_StartNode]][walknodeZ];
        WalkNPC[i][walknpc_Created]=1;
        printf("WalkNPC %d Load, skin %d node %d",i,WalkNPC[i][walknpc_Skin],WalkNPC[i][walknpc_StartNode]);
    }
    i++;
    if(i<sizeof(WalkNPC))
        SetTimerEx("WNPCreate", 10, 0, "d", i);
    return 1;
}
stock Float:GetDistance(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    return floatsqroot( (( x1 - x2 ) * ( x1 - x2 )) + (( y1 - y2 ) * ( y1 - y2 )) + (( z1 - z2 ) * ( z1 - z2 )) );
}
forward WNPCCheckPos(i);
public WNPCCheckPos(i)
{
    new Float:pos[3];
    NPC_GetPos(WalkNPC[i][walknpc_ID],pos[0],pos[1],pos[2]);
    new Float:dist=GetDistance(pos[0],pos[1],pos[2], WalkNodeInfo[WalkNPC[i][walknpc_NextNode]][walknodeX], WalkNodeInfo[WalkNPC[i][walknpc_NextNode]][walknodeY], WalkNodeInfo[WalkNPC[i][walknpc_NextNode]][walknodeZ]);
    if(dist<1.0)
    {
        WNPCNextNode(i);
    }		
    return 1;
}



public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/create", true))
    {
        new b=WNPCInit();
        new str[144];
        format(str,sizeof(str),"%d WNPCs Created",b);
        SendClientMessage(playerid,COLOR_YELLOW2,str);
        return 1;
    }
    if (!strcmp(cmdtext, "/destroy", true))
    {
        new b;
        for(new i; i<sizeof(WalkNPC); i++)
        {
            if(WalkNPC[i][walknpc_Created]==1)
            {
                NPC_Destroy(WalkNPC[i][walknpc_ID]);
                WalkNPC[i][walknpc_Created]=0;
                printf("WalkNPC %d destroy, skin %d node %d",i,WalkNPC[i][walknpc_Skin],WalkNPC[i][walknpc_StartNode]);
                b++;
            }
        }
        new str[144];
        format(str,sizeof(str),"%d WNPCs destroyed",b);
        SendClientMessage(playerid,COLOR_YELLOW2,str);
        return 1;
    }
    if (!strcmp(cmdtext, "/check", true))
    {
        new Float:pos[3];
	    for(new i=0; i<sizeof(WalkNPC); i++)
		{
		    if(WalkNPC[i][walknpc_Valid]==1)
			{
				NPC_GetPos(WalkNPC[i][walknpc_ID],pos[0],pos[1],pos[2]);
				if(IsPlayerInRangeOfPoint(playerid,5.0,pos[0],pos[1],pos[2]))
				{
				    new str[144];
				    format(str,sizeof(str),"ID %d, %s(%d), skin %d, start %d, old %d, next %d",
				    i,
				    WalkNPC[i][walknpc_Name],
				    WalkNPC[i][walknpc_ID],
				    WalkNPC[i][walknpc_Skin],
  					WalkNPC[i][walknpc_StartNode],
    				WalkNPC[i][walknpc_OldNode],
					WalkNPC[i][walknpc_NextNode]);
    				SendClientMessage(playerid,COLOR_YELLOW2,str);
				    return 1;
				}
			}
		}
        return 1;
    }
    if (!strcmp(cmdtext, "/restart", true))
    {
        for(new i=0; i<sizeof(WalkNPC); i++)
		{
		    if(WalkNPC[i][walknpc_Valid]==1)
			{
				WalkNPCStartMove(i);
			}
		}
		SendClientMessage(playerid,COLOR_WHITE,"All WNPC Restarted");
        return 1;
    }
    if (!strcmp(cmdtext, "/stop", true))
    {
        for(new i=0; i<sizeof(WalkNPC); i++)
		{
		    if(WalkNPC[i][walknpc_Valid]==1)
			{
				NPC_StopMove(WalkNPC[i][walknpc_ID]);
			}
		}
		SendClientMessage(playerid,COLOR_WHITE,"All WNPC Stopped");
        return 1;
    }
    if (!strcmp(cmdtext, "/start", true))
    {
        for(new i=0; i<sizeof(WalkNPC); i++)
		{
		    if(WalkNPC[i][walknpc_Valid]==1)
			{
				NPC_Move(WalkNPC[i][walknpc_ID], WalkNodeInfo[WalkNPC[i][walknpc_NextNode]][walknodeX], WalkNodeInfo[WalkNPC[i][walknpc_NextNode]][walknodeY], WalkNodeInfo[WalkNPC[i][walknpc_NextNode]][walknodeZ], 1);
			}
		}
		SendClientMessage(playerid,COLOR_WHITE,"All WNPC Started");
        return 1;
    }
    if (!strcmp(cmdtext, "/show", true))
    {
        new labelstr[255];
	    for(new i=1; i<sizeof(WalkNodeInfo); i++)
		{

            if(WalkNodeInfo[i][walknodeshowed])
            {
                DestroyDynamic3DTextLabel(WalkNodeInfo[i][walknodetext]);
                WalkNodeInfo[i][walknodeshowed] =0;
            }
            format(labelstr,255,"%d\n%s\n%d\n%d\n%d\n%d",i,
            WalkNodeInfo[i][walkNodeGroupName],
            WalkNodeInfo[i][walknextnode0],
            WalkNodeInfo[i][walknextnode1],
            WalkNodeInfo[i][walknextnode2],
            WalkNodeInfo[i][walknextnode3]);
            WalkNodeInfo[i][walknodetext] = CreateDynamic3DTextLabel(labelstr,
            ColorCounter(),
            WalkNodeInfo[i][walknodeX],
            WalkNodeInfo[i][walknodeY],
            WalkNodeInfo[i][walknodeZ],100.0);
            WalkNodeInfo[i][walknodeshowed] =1;
			
		}
		SendClientMessage(playerid,COLOR_WHITE,"All nodes showed");
		return 1;
    }
    if (!strcmp(cmdtext, "/hide", true))
    {
        for(new i=1; i<sizeof(WalkNodeInfo); i++)
		{

		    if(WalkNodeInfo[i][walknodeshowed])
		    {
		        DestroyDynamic3DTextLabel(WalkNodeInfo[i][walknodetext]);
		     	WalkNodeInfo[i][walknodeshowed] =0;
			}

		}
		SendClientMessage(playerid,COLOR_WHITE,"All nodes hided");
        return 1;
    }
    if (!strcmp(cmdtext, "/gotofk", true))
    {
        if (GetPlayerState(playerid) == 2)
		{
			new tmpcar = GetPlayerVehicleID(playerid);
			SetVehiclePos(tmpcar, -234.1000,1018.3232,19.5938);
		}
		else
			SetPlayerPos(playerid, -234.1000,1018.3232,19.5938);
        SendClientMessage(playerid,COLOR_WHITE,"Goto FK");
        return 1;
    }
    if (!strcmp(cmdtext, "/gotols", true))
    {
        if (GetPlayerState(playerid) == 2)
		{
			new tmpcar = GetPlayerVehicleID(playerid);
			SetVehiclePos(tmpcar, 1529.6,-1691.2,13.3);
		}
		else
			SetPlayerPos(playerid, 1529.6,-1691.2,13.3);
        SendClientMessage(playerid,COLOR_WHITE,"Goto LS");
        return 1;
    }
    if(!strcmp(cmdtext, "/car", true))
    {
        new Float:X,Float:Y,Float:Z;
        GetPlayerPos(playerid, X,Y,Z);
        CreateVehicle(451, X,Y,Z, 0.0, -1, -1, 60000);
        SendClientMessage(playerid,COLOR_WHITE,"One hot turismo for you");
        return 1;
    }
    return 0;
}


public OnNPCFinishMove(npcid)
{
    printf("OnNPCFinishMove NPC %d, WNPC %d finish move",npcid,PlayeridToWNPCid[npcid]);
    //NPC_StopMove(npcid);
    //SetTimerEx("WNPCNextNode", 1000, 0, "d", PlayeridToWNPCid[npcid]);
	WNPCNextNode(PlayeridToWNPCid[npcid]);
	return 1;
}
forward WNPCNextNode(i);
public WNPCNextNode(i)
{
	new thisnodeid=WalkNPC[i][walknpc_NextNode];
	new nd[5];
	new mnodes=0;
    if(WalkNodeInfo[thisnodeid][walknextnode0]>0 && WalkNodeInfo[thisnodeid][walknextnode0]!=WalkNPC[i][walknpc_OldNode])
    {
        nd[mnodes]=WalkNodeInfo[thisnodeid][walknextnode0];
        mnodes++;
    }
    if(WalkNodeInfo[thisnodeid][walknextnode1]>0 && WalkNodeInfo[thisnodeid][walknextnode1]!=WalkNPC[i][walknpc_OldNode])
    {
        nd[mnodes]=WalkNodeInfo[thisnodeid][walknextnode1];
        mnodes++;
    }
    if(WalkNodeInfo[thisnodeid][walknextnode2]>0 && WalkNodeInfo[thisnodeid][walknextnode2]!=WalkNPC[i][walknpc_OldNode])
    {
        nd[mnodes]=WalkNodeInfo[thisnodeid][walknextnode2];
        mnodes++;
    }
    if(WalkNodeInfo[thisnodeid][walknextnode3]>0 && WalkNodeInfo[thisnodeid][walknextnode3]!=WalkNPC[i][walknpc_OldNode])
    {
        nd[mnodes]=WalkNodeInfo[thisnodeid][walknextnode3];
        mnodes++;
    }
    new nextnode,nextnodeid;
    if(mnodes==0)
    {
        if(WalkNodeInfo[thisnodeid][walknextnode0]>0)
        {
            nextnodeid=WalkNodeInfo[thisnodeid][walknextnode0];
        }
        else if(WalkNodeInfo[thisnodeid][walknextnode1]>0)
        {
            nextnodeid=WalkNodeInfo[thisnodeid][walknextnode1];
        }
        else if(WalkNodeInfo[thisnodeid][walknextnode2]>0)
        {
            nextnodeid=WalkNodeInfo[thisnodeid][walknextnode2];
        }
        else if(WalkNodeInfo[thisnodeid][walknextnode3]>0)
        {
            nextnodeid=WalkNodeInfo[thisnodeid][walknextnode3];
        }
    }
    else
    {
    	nextnode=random(mnodes);
		nextnodeid=nd[nextnode];
	}
   	WalkNPC[i][walknpc_OldNode]=thisnodeid;
	WalkNPC[i][walknpc_NextNode]=nextnodeid;
	NPC_Move(WalkNPC[i][walknpc_ID], WalkNodeInfo[WalkNPC[i][walknpc_NextNode]][walknodeX], WalkNodeInfo[WalkNPC[i][walknpc_NextNode]][walknodeY], WalkNodeInfo[WalkNPC[i][walknpc_NextNode]][walknodeZ], 1);
	//printf("NPC %d, WNPC %d, moved to nextnode %d",WalkNPC[i][walknpc_ID],i,nextnodeid);
    WalkNPC[i][walknpc_Nodes]++;
	return 1;

}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    switch(newkeys)
	{
        case KEY_YES:
        {
            if(FindClosestWNPCAndStopIT(playerid))
                return 1;
        }
    }
    return 1;
}

forward FindClosestWNPCAndStopIT(playerid);
public FindClosestWNPCAndStopIT(playerid)
{
	new wnpcid = -1;
	wnpcid=GetClosestWNPC(playerid);
	if (wnpcid != -1)
    {
        if(WalkNPC[wnpcid][walknpc_PlayerID]==INVALID_PLAYER_ID)
        {
            NPC_StopMove(WalkNPC[wnpcid][walknpc_ID]);
            SelectedPlayerid[playerid]=wnpcid;
            
            new stra[144];
            format(stra,sizeof(stra),"WNPC %d, %s",wnpcid,WalkNPC[wnpcid][walknpc_Name]);
            ShowPlayerDialog(playerid,1,DIALOG_STYLE_MSGBOX,stra,"Follow you?","Follow Me","Cancel");
            return 1;
        }
        else
        {
            NPC_StopMove(WalkNPC[wnpcid][walknpc_ID]);
            SelectedPlayerid[playerid]=wnpcid;

            new stra[144];
            format(stra,sizeof(stra),"WNPC %d, %s",wnpcid,WalkNPC[wnpcid][walknpc_Name]);
            ShowPlayerDialog(playerid,2,DIALOG_STYLE_MSGBOX,stra,"Stop follow and back to node?","Back","Follow Me");
        }
	}
	return 0;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch (dialogid)
    {
        case 1:
        {
            if(response)
            {
                new wnpcid=SelectedPlayerid[playerid];
                if(WNPCFollowTimer[wnpcid]!=0)
                {
                    KillTimer(WNPCFollowTimer[wnpcid]);
                    WNPCFollowTimer[wnpcid]=0;
                }
                WalkNPC[wnpcid][walknpc_PlayerID]=playerid;
                FollowPlayer(wnpcid,playerid);
                WNPCFollowTimer[wnpcid]=SetTimerEx("FollowPlayer", 2000, 1, "dd", wnpcid,playerid);
            }
            else
            {
                new wnpcid=SelectedPlayerid[playerid];
                if(WNPCFollowTimer[wnpcid]!=0)
                {
                    KillTimer(WNPCFollowTimer[wnpcid]);
                    WNPCFollowTimer[wnpcid]=0;
                }
                NPC_Move(WalkNPC[wnpcid][walknpc_ID], WalkNodeInfo[WalkNPC[wnpcid][walknpc_NextNode]][walknodeX], WalkNodeInfo[WalkNPC[wnpcid][walknpc_NextNode]][walknodeY], WalkNodeInfo[WalkNPC[wnpcid][walknpc_NextNode]][walknodeZ], 1);
                WalkNPC[wnpcid][walknpc_PlayerID]=INVALID_PLAYER_ID;
            }
            return 1;
        }
        case 2:
        {
            if(response)
            {
                new wnpcid=SelectedPlayerid[playerid];
                if(WNPCFollowTimer[wnpcid]!=0)
                {
                    KillTimer(WNPCFollowTimer[wnpcid]);
                    WNPCFollowTimer[wnpcid]=0;
                }
                NPC_Move(WalkNPC[wnpcid][walknpc_ID], WalkNodeInfo[WalkNPC[wnpcid][walknpc_NextNode]][walknodeX], WalkNodeInfo[WalkNPC[wnpcid][walknpc_NextNode]][walknodeY], WalkNodeInfo[WalkNPC[wnpcid][walknpc_NextNode]][walknodeZ], 1);
                WalkNPC[wnpcid][walknpc_PlayerID]=INVALID_PLAYER_ID;
            }
            else
            {
                new wnpcid=SelectedPlayerid[playerid];
                if(WNPCFollowTimer[wnpcid]!=0)
                {
                    KillTimer(WNPCFollowTimer[wnpcid]);
                    WNPCFollowTimer[wnpcid]=0;
                }
                WalkNPC[wnpcid][walknpc_PlayerID]=playerid;
                FollowPlayer(wnpcid,playerid);
                WNPCFollowTimer[wnpcid]=SetTimerEx("FollowPlayer", 2000, 1, "dd", wnpcid,playerid);
            }
            return 1;
        }
    }
    return 1;
}

forward FollowPlayer(wnpcid,playerid);
public FollowPlayer(wnpcid,playerid)
{
    if(IsPlayerConnected(playerid))
    {
        new Float:pos[6];
        GetPlayerPos(playerid, pos[0],pos[1],pos[2]);
        NPC_GetPos(WalkNPC[wnpcid][walknpc_ID], pos[3],pos[4],pos[5]);
        new Float:dist=GetDistance(pos[0],pos[1],pos[2],pos[3],pos[4],pos[5]);
        if(dist>5.0)
        {
            NPC_Move(WalkNPC[wnpcid][walknpc_ID],pos[0],pos[1],pos[2], 2);
        }
        else
        {
            NPC_Move(WalkNPC[wnpcid][walknpc_ID],pos[0],pos[1],pos[2], 1);
        }
        
    }
    else
    {
        if(WNPCFollowTimer[wnpcid]!=0)
        {
            KillTimer(WNPCFollowTimer[wnpcid]);
            WNPCFollowTimer[wnpcid]=0;
        }
    
        NPC_Move(WalkNPC[wnpcid][walknpc_ID], WalkNodeInfo[WalkNPC[wnpcid][walknpc_NextNode]][walknodeX], WalkNodeInfo[WalkNPC[wnpcid][walknpc_NextNode]][walknodeY], WalkNodeInfo[WalkNPC[wnpcid][walknpc_NextNode]][walknodeZ], 1);
        WalkNPC[wnpcid][walknpc_PlayerID]=INVALID_PLAYER_ID;
    }
    return 1;
}

stock GetClosestWNPC(playerid)
{
	new biz=-1;
	new Float:dist=99999.9;
	new Float:pos[6];
	new Float:dist2;
	GetPlayerPos(playerid,pos[0],pos[1],pos[2]);
	for(new i; i<sizeof(WalkNPC); i++)
	{
		if(WalkNPC[i][walknpc_Valid]==1)
		{
            NPC_GetPos(WalkNPC[i][walknpc_ID], pos[3],pos[4],pos[5]);
            dist2=GetDistance(pos[0],pos[1],pos[2],pos[3],pos[4],pos[5]);
            if(dist2<dist)
            {
                dist=dist2;
                biz=i;
            }
		}
	}
	if(dist>4.0) return -1;
	return biz;
}