#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <cstrike>
#include <engine>

#define PLUGIN	"VIP Aktivator"
#define AUTHOR	"Kalendarky"
#define VERSION	"1.2 FIX"

new Host[]     = ""
new User[]    = ""
new Pass[]     = ""
new Db[]     = ""

new Handle:g_SqlTuple
new g_Error[512];

new flagss[32];

new steamid[128],flagy[32]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_concmd("amx_addvip", "ADD_VIP", ADMIN_RCON , "<steamid> <flags>");
	set_task(0.01, "MySql_Init");
}	
public MySql_Init()
{
	g_SqlTuple = SQL_MakeDbTuple(Host,User,Pass,Db)


	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_SqlTuple,ErrorCode,g_Error,charsmax(g_Error))
    
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error);
    
	//Vytvori tabulku v databazi (s menom serveru) keby ste mali istu db na viacerich serverov.. :)
	new szHostName[512];
	get_cvar_string("hostname", szHostName, charsmax(szHostName));
	
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
public client_connect(player)
{
    if( !is_user_hltv(player) && !is_user_bot(player) )
    {
		Load_MySql(player);
    }
}
public ADD_VIP(id,level,cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	read_argv(1, steamid, 127);
	read_argv(2, flagy, 31);
	
	new szTemp[512];
	new szHostName[255];
	get_cvar_string( "hostname", szHostName, charsmax( szHostName ) );
	
	format(szTemp,charsmax(szTemp),"INSERT INTO `%s` ( `steamid` , `flags`)VALUES ('%s','%s');",szHostName,steamid[id],flagy);
	SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
	
	return PLUGIN_HANDLED;
}
public GiveVIP(id) 
{
	remove_user_flags(id,get_user_flags(id));
	set_user_flags(id,read_flags(flagss[id]));
}
//MYSQL
public Load_MySql(id)
{
	new szSteamId[128], szTemp[512]
	get_user_authid(id, szSteamId, charsmax(szSteamId))
    
	new Data[1]
	Data[0] = id
	new szHostName[512];
	get_cvar_string("hostname", szHostName, charsmax(szHostName));
	
	format(szTemp,charsmax(szTemp),"SELECT * FROM `%s` WHERE (`steamid` = '%s')", szHostName,szSteamId)
	SQL_ThreadQuery(g_SqlTuple,"register_vips",szTemp,Data,1)
}
public register_vips(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
    if(FailState == TQUERY_CONNECT_FAILED)
    {
        log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error)
    }
    else if(FailState == TQUERY_QUERY_FAILED)
    {
        log_amx("Load Query failed. [%d] %s", Errcode, Error)
    }

    new id
    id = Data[0]
    
    if(SQL_NumResults(Query) < 1) 
    {
		return PLUGIN_HANDLED;
    } 
    else 
    {
		new tempflagss[32];
		SQL_ReadResult( Query , 1 ,tempflagss , charsmax( tempflagss ) );
		copy(flagss[id],31,tempflagss);
		GiveVIP(id);
    }
    
    return PLUGIN_HANDLED
}
public IgnoreHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
    SQL_FreeHandle(Query)
    
    return PLUGIN_HANDLED
}
//MYSQL END
