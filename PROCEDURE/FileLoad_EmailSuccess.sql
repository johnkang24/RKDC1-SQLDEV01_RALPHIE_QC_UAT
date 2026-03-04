CREATE PROCEDURE [dbo].[FileLoad_EmailSuccess]  @in_fb0RecordID int  as

--declare @in_fb0RecordID int  = 19300

declare @msg_subject		nvarchar(max)
declare @msg_body			nvarchar(max)
declare @msg_to				nvarchar(max)
declare @PrimaryEmail		varchar(255)
declare @SecondaryEmail		varchar(255)
declare @TechnicalEMail		varchar(255)
declare @QCFileLoadEmail	varchar(255)

declare @fb0_jobnumber		varchar(255)
declare @fb0_client			varchar(50)
declare @proc_jobname		varchar(255)

--JCK:03.03.2023 - added to attach NCOA report
declare @fb0_SchemaName		varchar(50)
declare @fb0_ClientType						varchar(50)
declare @fb0_StorageCategory				varchar(50)
declare @job_NCOAReportFile					varchar(200)

declare @ServerName							varchar(255)
set @ServerName		= dbo.Ralphie_GetDataServerName (@in_fb0RecordID)

select @fb0_ClientType = a.fb1_column02
	from dbo.fb1_SpreadsheetInterface as a
	where a.fb1_fb0recordID = @in_fb0RecordID and a.fb1_tab = 'JobControl' and a.fb1_column01= 'Client Type'
select @fb0_StorageCategory = a.fb1_column02
	from dbo.fb1_SpreadsheetInterface as a
	where a.fb1_fb0recordID = @in_fb0RecordID and a.fb1_tab = 'JobControl' and a.fb1_column01= 'Storage Category'

select @fb0_jobnumber = fb0_jobnumber, @fb0_client = fb0_client, @fb0_SchemaName = fb0_SchemaName
	from dbo.fb0_Jobs
	where fb0_recordID = @in_fb0RecordID

set @PrimaryEmail = (select fb1_column02 from dbo.fb1_SpreadsheetInterface (nolock) 
									where fb1_fb0recordid = @in_fb0RecordID and fb1_tab = 'JobControl' and fb1_column01 = 'Email Address')
set @SecondaryEmail = (select fb1_column02 from dbo.fb1_SpreadsheetInterface (nolock) 
									where fb1_fb0recordid = @in_fb0RecordID and fb1_tab = 'JobControl' and fb1_column01 = 'Secondary Email Address')
set @TechnicalEMail = (select fb1_column02 from dbo.fb1_SpreadsheetInterface (nolock) 
									where fb1_fb0recordid = @in_fb0RecordID and fb1_tab = 'JobControl' and fb1_column01 = 'Technical Email Address')
set @QCFileLoadEmail = (select fb1_column02 from dbo.fb1_SpreadsheetInterface (nolock) 
									where fb1_fb0recordid = @in_fb0RecordID and fb1_tab = 'JobControl' and fb1_column01 = 'Notification - QC File Load')
set @QCFileLoadEmail = 'jkang@rkdgroup.com'

set @msg_to = case when @PrimaryEmail is not null	 then rtrim(@PrimaryEmail) + '; ' else '' end +
			  case when @SecondaryEmail is not null	 then rtrim(@SecondaryEmail) + '; ' else '' end +
			  case when @TechnicalEmail is not null  then rtrim(@TechnicalEmail) else '' end

set @proc_jobname = rtrim(@fb0_client) + '_' + @fb0_jobnumber


set @msg_subject = 'Ralphie QC File Loaded Successfully: ' + @proc_jobname
set @msg_body = 'The QC files loaded successfully at ' + 	convert(varchar(20),GETDATE(),121) + '. '  + CHAR(13) +
				'Below QC file is now ready to be approved/rejected.' + CHAR(13) 

exec msdb.dbo.sp_send_dbmail
		@profile_name = NULL
	,@recipients = @msg_to
	,@subject = @msg_subject
	,@body_format = 'HTML'
	,@body = @msg_body

