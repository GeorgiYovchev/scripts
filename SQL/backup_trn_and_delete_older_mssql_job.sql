DECLARE @path VARCHAR(500) 
DECLARE @name VARCHAR(500) 
DECLARE @pathwithname VARCHAR(500) 
DECLARE @time DATETIME 
DECLARE @year VARCHAR(4) 
DECLARE @month VARCHAR(2) 
DECLARE @day VARCHAR(2) 
DECLARE @minute VARCHAR(2)
DECLARE @cutoffDate VARCHAR(20)

SET @path = 'F:\Backup\'
SET @cutoffDate = CONVERT(VARCHAR(20), DATEADD(DAY, -7, GETDATE()), 120)

EXEC master.dbo.xp_delete_file 
    0,
    @path,
    'trn',
    @cutoffDate;

SELECT @time = GETDATE() 
SELECT @year = (SELECT CONVERT(VARCHAR(4), DATEPART(yy, @time))) 
SELECT @month = (SELECT CONVERT(VARCHAR(2), FORMAT(DATEPART(mm,@time),'00'))) 
SELECT @day = (SELECT CONVERT(VARCHAR(2), FORMAT(DATEPART(dd,@time),'00'))) 
SELECT @minute = (SELECT CONVERT(VARCHAR(2), FORMAT(DATEPART(mi,@time),'00')))

SELECT @name ='Nra' + '_' + @year + @month + @day + @minute
SET @pathwithname = @path + @namE + '.trn' 

BACKUP LOG [Nra]
TO DISK = @pathwithname WITH NOFORMAT, NOINIT,
NAME = N'TSQL-TRN Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10