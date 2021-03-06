DECLARE @command varchar(2000);
SELECT @command = 'IF ''?'' NOT IN(''master'', ''model'', ''msdb'', ''tempdb'') BEGIN USE ?
IF NOT EXISTS (
		SELECT *
		FROM	sys.server_principals
		WHERE	name = ''svc_change_automation''
			)
	BEGIN
		CREATE LOGIN [svc_change_automation] WITH PASSWORD=N''W!48iZ6^btr7pjTg''
			, DEFAULT_DATABASE=[master]
			, DEFAULT_LANGUAGE=[us_english]
			, CHECK_EXPIRATION=OFF
			, CHECK_POLICY=ON
	END

IF DATABASE_PRINCIPAL_ID(''svc_change_automation'') IS NULL
	BEGIN
		CREATE USER [svc_change_automation] FOR LOGIN [svc_change_automation] WITH DEFAULT_SCHEMA=[dbo]
	END
ALTER ROLE [db_owner] ADD MEMBER [svc_change_automation]
END   ' 
print @command

EXEC sp_MSforeachdb @command 