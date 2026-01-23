USE ultraplay;
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql + N'UPDATE STATISTICS dbo.accountStatement ' 
    + QUOTENAME(s.name) + N';' + CHAR(13) + CHAR(10)
FROM sys.stats s
WHERE s.object_id = OBJECT_ID('dbo.accountStatement')
  AND s.name NOT LIKE '_WA%';

EXEC sp_executesql @sql;