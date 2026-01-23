DECLARE @path VARCHAR(500) 
DECLARE @name VARCHAR(500) 
DECLARE @pathwithname VARCHAR(500) 
DECLARE @time DATETIME 
DECLARE @year VARCHAR(4) 
DECLARE @month VARCHAR(2) 
DECLARE @day VARCHAR(2) 
DECLARE @hour VARCHAR(2)
DECLARE @minute VARCHAR(2)

SET @path = 's3://oddstech-backup.s3.eu-central-3.ionoscloud.com/stage-mssql/'
SELECT @time = GETDATE() 
SELECT @year = (SELECT CONVERT(VARCHAR(4), DATEPART(yy, @time))) 
SELECT @month = (SELECT CONVERT(VARCHAR(2), FORMAT(DATEPART(mm,@time),'00'))) 
SELECT @day = (SELECT CONVERT(VARCHAR(2), FORMAT(DATEPART(dd,@time),'00'))) 
SELECT @hour = (SELECT CONVERT(VARCHAR(2), FORMAT(DATEPART(hh,@time),'00')))
SELECT @minute = (SELECT CONVERT(VARCHAR(2), FORMAT(DATEPART(mi,@time),'00')))
SELECT @name ='Ultraplay' + '_' + @year + @month + @day + @hour + @minute
SET @pathwithname = @path + @name + '.trn' 

BACKUP LOG ultraplay 
TO URL = @pathwithname 
WITH COMPRESSION, FORMAT, MAXTRANSFERSIZE = 20971520;