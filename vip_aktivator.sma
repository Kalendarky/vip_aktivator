/* LICENSE: https://github.com/Kalendarky/license/blob/master/v1/LICENSE.md */
/* flagmg: https://github.com/Kalendarky/Flagmanager */

#define PLUGIN_NAME           "VIP/Flags Manager"
#define PLUGIN_AUTHOR         "Kalendarky"
#define PLUGIN_VERSION        "2.0"

#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <flagmg>

new const Host[] = "";
new const User[] = "";
new const Pass[] = "";
new const Db[] = "";

new Handle:g_SqlTuple;

new szSteamId[128], szTemp[512],flags[33];
new szHostName[512];

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	register_concmd("amx_addflags", "ADD_FLAGS", ADMIN_RCON , "<steamid> <flags>");
	
	set_task(1.0, "MySql_Init");
}
public MySql_Init()
{
	g_SqlTuple = SQL_MakeDbTuple(Host,User,Pass,Db)
	
	get_cvar_string("hostname", szHostName, charsmax(szHostName));
	
	new g_Error[512];
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_SqlTuple,ErrorCode,g_Error,charsmax(g_Error))
	
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error);
	
	new Handle:Queries;
	Queries = SQL_PrepareQuery(SqlConnection,"CREATE TABLE IF NOT EXISTS `%s` (steamid varchar(128),flags varchar(32))",szHostName)
	
	if(!SQL_Execute(Queries))
	{
		SQL_QueryError(Queries,g_Error,charsmax(g_Error));
		set_fail_state(g_Error);
	}
	
	SQL_FreeHandle(Queries);
	
	SQL_FreeHandle(SqlConnection);
}
public client_connect(id)
{
	if( !is_user_hltv(id) && !is_user_bot(id) && is_user_connected(id) )
	{
		Load_MySql(id);
	}
}
public Load_MySql(id)
{
	get_user_authid(id, szSteamId, charsmax(szSteamId))
	
	new DataArray[1];
	DataArray[0] = id;
	
	format(szTemp,charsmax(szTemp),"SELECT * FROM `%s` WHERE (`steamid` = '%s')", szHostName,szSteamId)
	SQL_ThreadQuery(g_SqlTuple,"register_flags",szTemp,DataArray,1);
}
public register_flags(FailState,Handle:Query,Error[],Errcode,DataArray[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error)
		
		SQL_FreeHandle(Query);
		return PLUGIN_HANDLED;
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Load Query failed. [%d] %s", Errcode, Error)
		
		SQL_FreeHandle(Query);
		return PLUGIN_HANDLED;
	}
	
	if(SQL_NumResults(Query) < 1) 
	{
		SQL_FreeHandle(Query);
		return PLUGIN_HANDLED;
	} 
	else
	{
		new id;
		id = DataArray[0];
		
		SQL_ReadResult( Query , 1 ,flags , charsmax( flags ) );
		flagmg_Addflags(id, flags);
		
		SQL_FreeHandle(Query);
		return PLUGIN_HANDLED;
	}
}
public ADD_FLAGS(id,level,cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	read_argv(1, szSteamId, charsmax(szSteamId));
	read_argv(2, flags, charsmax(flags));
	
	
	format(szTemp,charsmax(szTemp),"INSERT INTO `%s` ( `steamid` , `flags`)VALUES ('%s','%s');",szHostName,szSteamId,flags);
	SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
	
	return PLUGIN_HANDLED;
}
public plugin_end()
{
	SQL_FreeHandle(g_SqlTuple);
}

public IgnoreHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Load Query failed. [%d] %s", Errcode, Error)
	}
	SQL_FreeHandle(Query)
	
	return PLUGIN_HANDLED;
}
