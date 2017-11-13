if exists (	select 1 from Information_Schema.Tables where TABLE_Name = 'logDatabaseChange') begin
  if exists (select 1 from logDatabaseChange where ChangeLogGuid = 'F6F5AA6A-EA7C-414A-A14D-9B3D3FEF8D36' and FileVersion = 5 and ChangeStatusId = 110) begin
    print 'Change script will not be Deployed as an equal or higher version was successfully Deployed.'
    set noexec on;
  end
end

set quoted_identifier off;
go

set ansi_nulls off;
go

if exists
(
	select
		1
	from
		Information_Schema.Tables
	where Table_Name = N'logDatabaseChange'
)
begin
	drop table logDatabaseChange;
end;

if not exists
(
	select
		1
	from
		Information_Schema.Tables
	where Table_Name = N'logDatabaseChange'
)
begin
	create table logDatabaseChange
	(
		ChangeLogGuid uniqueidentifier not null,
		FileVersion tinyint not null,
    ChangeStatusId tinyint not null,
		ExecutionContextId int not null,
		[FileName] nvarchar(500) not null,
		[Description] nvarchar(max) null,
		CreatedDate datetime default getdate() not null,
		CreatedBy varchar(50) default system_user not null,
    UpdatedDate datetime not null default getdate(),
		UpdatedBy varchar(50) default system_user not null,
		constraint PK_logDatabaseChange primary key nonclustered(ChangeLogGuid asc, FileVersion asc)
		with(ignore_dup_key = off) on [Primary]
	)
	on [Primary];
end;
go

if exists
(
	select
		1
	from
		Information_Schema.Tables
	where Table_Name = N'logDatabaseChangeContext'
)
begin
	drop table logDatabaseChangeContext;
end;

if not exists
(
	select
		1
	from
		Information_Schema.Tables
	where Table_Name = N'logDatabaseChangeContext'
)
begin
	create table logDatabaseChangeContext
	(
    ExecutionContextId int not null,
    ExecutionContext nvarchar(50) not null,
    CreatedDate datetime not null default getdate(),
		CreatedBy varchar(50) default system_user not null,
    UpdatedDate datetime not null default getdate(),
		UpdatedBy varchar(50) default system_user not null,
		constraint PK_logDatabaseChangeConfiguration primary key clustered(ExecutionContextId)
		with(ignore_dup_key = off) on [Primary]
  )
	on [Primary];
end;
go

if exists
(
	select
		1
	from
		Information_Schema.Tables
	where Table_Name = N'logDatabaseChangeStatus'
)
begin
	drop table logDatabaseChangeStatus;
end;

if not exists
(
	select
		1
	from
		Information_Schema.Tables
	where Table_Name = N'logDatabaseChangeStatus'
)
begin
	create table logDatabaseChangeStatus
	(
    ChangeStatusId tinyint not null,
    [Description] nvarchar(50) not null
		constraint PK_logDatabaseChangeStatus primary key nonclustered(ChangeStatusId)
		with(ignore_dup_key = off) on [Primary]
	)
	on [Primary];
end;
go

if not exists (select 1 from information_schema.table_constraints where table_name = N'logDatabaseChange' and constraint_name = N'FK_logDatabaseChange_ExecutionContextId')
	alter table [dbo].[logDatabaseChange] with check 
		add constraint [FK_logDatabaseChange_ExecutionContextId] foreign key(ExecutionContextId)
		references [dbo].logDatabaseChangeContext (ExecutionContextId)
go

if not exists (select 1 from information_schema.table_constraints where table_name = N'logDatabaseChange' and constraint_name = N'FK_logDatabaseChange_ChangeStatusId')
	alter table [dbo].[logDatabaseChange] with check 
		add constraint [FK_logDatabaseChange_ChangeStatusId] foreign key(ChangeStatusId)
		references [dbo].logDatabaseChangeStatus(ChangeStatusId)
go

if exists
(
	select
		1
	from
		Information_Schema.Routines
	where Routine_Name = 'logDatabaseChangeUpdate'
				and Routine_Type = 'PROCEDURE'
)
begin
	drop procedure
		dbo.logDatabaseChangeUpdate;
end;
go

create procedure dbo.logDatabaseChangeUpdate(
	@guid uniqueidentifier,
	@version tinyint,
  @changeStatusId tinyint
  )
as
	set nocount on;

  if exists (
    select
      1
    from
      logDatabaseChange
    where
      ChangeLogGuid = @guid
		and
      FileVersion >= @version
    and
      ChangeStatusId = 110
    and
      @changeStatusId = 100
  )begin
    print 'Cannot update logDatabaseChange status to "Deploy - Queued" because an equal or higher version has already been successfully Deployed.';
    --throw 90000, 'Cannot update logDatabaseChange status to "Deploy - Queued" because this version has already been successfully Deployed', 1;
    return;
  end

  if exists (
    select
      1
    from
      logDatabaseChange
    where
      ChangeLogGuid = @guid
		and
      FileVersion >= @version
    and
      ChangeStatusId = 210
    and
      @changeStatusId = 200
  )begin
    print 'Cannot update logDatabaseChange status to "Undeploy - Queued" because an equal or higher version has already been successfully Undeployed.';
    --throw 90000, 'Cannot update logDatabaseChange status to "Undeploy - Queued" because this version has already been successfully Undeployed', 1;
    return;
  end

  if exists (
    select
      1
    from
      logDatabaseChange
    where
      ChangeLogGuid = @guid
		and
      FileVersion = @version
    and
      ChangeStatusId != 100
    and
      @changeStatusId in (105, 110)
  )begin
    print 'Cannot update logDatabaseChange status to "Deploy - Completed" because starting status is not "Deploy - Queued".';
    --throw 90000, 'Cannot update logDatabaseChange status to "Deploy - Completed" or "Deploy - Errored" because starting status is not "Deploy - Queued"', 1;
    return;
  end

  if exists (
    select
      1
    from
      logDatabaseChange
    where
      ChangeLogGuid = @guid
		and
      FileVersion = @version
    and
      ChangeStatusId != 200
    and
      @changeStatusId in (205, 210)
  )begin
    print 'Cannot update logDatabaseChange status to "Undeploy - Completed" because starting status is not "Undeploy - Queued".';
    --throw 90001, 'Cannot update logDatabaseChange status to "Undeploy - Completed" or "Undeploy - Errored" because starting status is not "Undeploy - Queued"', 1;
    return;
  end

	update
    logDatabaseChange
  set
    ChangeStatusId = @changeStatusId,
    UpdatedDate = getdate(),
    UpdatedBy = system_user
	where
    ChangeLogGuid = @guid
  and
    FileVersion = @version;

  declare @status_description nvarchar(50)
  select @status_description = [Description] from logDatabaseChangeStatus where ChangeStatusId = @changeStatusId
  print 'logDatabaseChange status updated to "' + @status_description + '".';

	set nocount off;
go

grant execute on dbo.logDatabaseChangeUpdate to Public;
go

if exists
(
	select
		1
	from
		Information_Schema.Routines
	where Routine_Name = 'logDatabaseChangeInsert'
				and Routine_Type = 'PROCEDURE'
)
begin
	drop procedure
		dbo.logDatabaseChangeInsert;
end;
go

create procedure dbo.logDatabaseChangeInsert(
  @guid uniqueidentifier,
	@version tinyint,
  @changeStatusId tinyint,
  @executionContextId int,
	@fileName varchar(500),
	@desc varchar(max) = null)
as
	set nocount on;

  if not exists (select 1 from logDatabaseChangeContext where ExecutionContextId = @executionContextId) begin
    declare @errorMsg varchar(500) = 'Cannot run change script because a record matching ExecutionContextId ' + cast(@executionContextId as varchar) + ' does not exist in the logDatabaseChangeContext table.';
    print @errorMsg;
    throw 90001, @errorMsg, 1
    return;
  end

  if exists (select 1 from logDatabaseChange where ChangeLogGuid = @guid and FileVersion = @version) begin
    exec logDatabaseChangeUpdate @guid, @version, @changeStatusId
  end
  else begin
    insert into logDatabaseChange
	  (
		  ChangeLogGuid,
		  FileVersion,
      ChangeStatusId,
		  ExecutionContextId,
		  [FileName],
		  [Description]
	  )
	  values
	  (
		  @guid, @version, @changeStatusId, @executionContextId, @fileName, @desc
	  );

    declare @status_description nvarchar(50)
    select @status_description = [Description] from logDatabaseChangeStatus where ChangeStatusId = @changeStatusId
    print 'logDatabaseChange status inserted as "' + @status_description + '".';
  end
	set nocount off;
go

grant execute on dbo.logDatabaseChangeInsert to Public;
go

if exists
(
	select
		1
	from
		Information_Schema.Routines
	where Routine_Name = 'logCanDatabaseChangeBeDeployed'
				and Routine_Type = 'PROCEDURE'
)
begin
	drop procedure
		dbo.logCanDatabaseChangeBeDeployed;
end;
go

create procedure dbo.logCanDatabaseChangeBeDeployed
(
	@guid uniqueidentifier,
	@version tinyint
)
as
	begin

    if exists
		(
			select
				1
			from
				logDatabaseChange
      where
        ChangeLogGuid = @guid
				and FileVersion >= @version
        and ChangeStatusId = 200
		)begin
       print 'Change script will not be Deployed as Undeploy is Queued for an equal or higher version.'
       return 1; --denied
    end

		if exists
		(
			select
				1
			from
				logDatabaseChange
			where ChangeLogGuid = @guid
						and FileVersion >= @version
            and ChangeStatusId = 110
		)
		begin
    	print 'Change script will not be Deployed as an equal or higher version was successfully Deployed.';
      print 'If you have made updates to this script, please increment the version number and re-run the script.';
			return 1; --denied
		end;

    if exists
		(
			select
				1
			from
				logDatabaseChange
			where ChangeLogGuid = @guid
						and FileVersion = @version
            and ChangeStatusId = 100
		)
		begin
      print 'Change script is Deploying...'
			return 0; --approved
		end;

    print 'Change script will not be Deployed'
    return 1; --denied
	end;
go

grant execute on dbo.logCanDatabaseChangeBeDeployed to Public;
go

-- remove old version of proc
if exists
(
	select
		1
	from
		Information_Schema.Routines
	where Routine_Name = 'logCanDatabaseChangeBeRolledback'
				and Routine_Type = 'PROCEDURE'
)
begin
	drop procedure
		dbo.logCanDatabaseChangeBeRolledback;
end;
go

if exists
(
	select
		1
	from
		Information_Schema.Routines
	where Routine_Name = 'logCanDatabaseChangeBeUndeployed'
				and Routine_Type = 'PROCEDURE'
)
begin
	drop procedure
		dbo.logCanDatabaseChangeBeUndeployed;
end;
go

create procedure dbo.logCanDatabaseChangeBeUndeployed
(
	@guid uniqueidentifier,
	@version tinyint
)
as
	begin

    if exists
		(
			select
				1
			from
				logDatabaseChange
			where ChangeLogGuid = @guid
						and FileVersion >= @version
            and ChangeStatusId = 210
		)
		begin
			print 'Change script will not be Undeployed as this version or a higher version was already successfully Undeployed.';
      print 'If you have made updates to this script, please increment the version number and re-run the script.';
      return 1; --denied
		end;

    if exists
		(
			select
				1
			from
				logDatabaseChange
			where
        ChangeLogGuid = @guid
				and FileVersion > @version
        and ChangeStatusId = 110
		) begin
      print 'Change script will not be Undeployed as a higher version of this change was successfully Deployed and not Undeployed.';
      print 'If you have made updates to this script, please increment the version number and re-run the script.';
      return 1; --denied
    end

 		if exists
		(
			select
				1
			from
				logDatabaseChange
			where ChangeLogGuid = @guid
						and FileVersion = @version
            and ChangeStatusId = 200
		)
		begin
      print 'Change script is Undeploying...'
			return 0; --approved
		end;

    if exists
		(
			select
				1
			from
				logDatabaseChange
			where ChangeLogGuid = @guid
						and FileVersion = @version
            and ChangeStatusId = 100
		)
		begin
      print 'Change script is Undeploying as a prerequisite of executing Deploy...'
			return 0; --approved
		end;

    print 'Change script will not be Undeployed as status is neither "Deploy - Queued" or "Undeploy - Queued"'
    return 1; --denied
	end;
go

grant execute on dbo.logCanDatabaseChangeBeUndeployed to Public;
go

insert into logDatabaseChangeContext
(ExecutionContextId, ExecutionContext)
values(0, 'logDatabaseChange')

insert into logDatabaseChangeStatus
(ChangeStatusId, [Description])
values
  (100, N'Deploy - Queued'),
  (105, N'Deploy - Errored'),
  (110, N'Deploy - Completed'),
  (200, N'Undeploy - Queued'),
  (205, N'Undeploy - Errored'),
  (210, N'Undeploy - Completed')

exec logDatabaseChangeInsert
	'F6F5AA6A-EA7C-414A-A14D-9B3D3FEF8D36',
	5,
  110,
	0,
	'logDatabaseChangeWithUndeploy_deploy.sql',
	'Create logDatabaseChange stored procedures, udfs, and tables';

set quoted_identifier off;
go

set ansi_nulls off;
go

set noexec off;