/* CHANGE SCRIPT MASTER TEMPLATE V2.0 */
/*     Git Hash: TOKEN[GIT_HASH] */
/* Compile Date: TOKEN[COMPILATION_DATETIME] */
set nocount on;
set xact_abort on;

--- METADATA BEGIN ---
begin try
  print @@servername + '.' + db_name() + ' - Starting change script - File: ' + TOKEN[FILE_NAME] + ' - ChangeLogGuid: ' + TOKEN[CHANGE_SCRIPT_GUID] + '- Version: ' + cast(TOKEN[VERSION] as varchar);
  exec logDatabaseChangeInsert
     @fileName =  TOKEN[FILE_NAME]
    ,@desc = TOKEN[DESCRIPTION]
    ,@executionContextId = TOKEN[EXECUTING_CONTEXT]
    ,@guid = TOKEN[CHANGE_SCRIPT_GUID]
    ,@version = TOKEN[VERSION]
    ,@changeStatusId = TOKEN[CHANGE_STATUS]; 
end try
begin catch
  throw;
end catch
go
--- METADATA END ---

declare @CanUndeploy tinyint = 0
exec @CanUndeploy = dbo.logCanDatabaseChangeBeUndeployed TOKEN[CHANGE_SCRIPT_GUID], TOKEN[VERSION]
if (@@error > 0 or @CanUndeploy != 0) begin
  set noexec on --disable script execution
end
go

--- UNDEPLOY BEGIN ---
begin try

SECTION[UNDEPLOY_SCRIPT]

  --update entry in Database Change Log for rolled back version
  exec logDatabaseChangeUpdate TOKEN[CHANGE_SCRIPT_GUID], TOKEN[VERSION], 210 --Undeploy - Completed
  print 'Change script successfully Undeployed'
end try
begin catch
  --update entry in Database Change Log for rolled back version error
  exec logDatabaseChangeUpdate TOKEN[CHANGE_SCRIPT_GUID], TOKEN[VERSION], 205 --Undeploy - Errored
  print 'Change script failed during Undeploy'
  print '*** PLEASE CHECK AND RESOLVE ERROR IN FILE: ' + TOKEN[FILE_NAME] + ' ***'
end catch

set noexec off
go
--- UNDEPLOY END ---

declare @CanDeploy tinyint = 0;
exec @CanDeploy = dbo.logCanDatabaseChangeBeDeployed TOKEN[CHANGE_SCRIPT_GUID], TOKEN[VERSION]
if (@@error > 0 or @CanDeploy != 0) begin
	set noexec on; --disable script execution
end
go

--- DEPLOY BEGIN ---
begin try

SECTION[DEPLOY_SCRIPT]

  --update entry in Database Change Log for deployed version
  exec logDatabaseChangeUpdate TOKEN[CHANGE_SCRIPT_GUID], TOKEN[VERSION], 110 --Deploy - Completed
  print 'Change script successfully Deployed'
end try
begin catch
  --update entry in Database Change Log for deployed version error
  exec logDatabaseChangeUpdate TOKEN[CHANGE_SCRIPT_GUID], TOKEN[VERSION], 105 --Deploy - Errored
  print 'Change script failed during Deploy'
  print '*** PLEASE CHECK AND RESOLVE ERROR IN FILE: ' + TOKEN[FILE_NAME] + ' ***'
  
  declare @errorMsg nvarchar(max)
  select @errorMsg = error_message()
  print @errorMsg;
  throw 90001, @errorMsg, 1
  return;
end catch

set noexec off
go
--- DEPLOY END ---

set xact_abort off;
set nocount off;
