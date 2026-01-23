DECLARE @job_names TABLE (job_name NVARCHAR(100));
DECLARE @job_name NVARCHAR(100);
DECLARE @last_run_status INT;
DECLARE @last_run_time DATETIME;
DECLARE @enabled INT;
DECLARE @server_name NVARCHAR(100);

-- Get the server name
SET @server_name = @@SERVERNAME;

-- Add the job names you want to monitor
INSERT INTO @job_names (job_name)
VALUES 
    ('LSBackup_UltraPlay');  -- Add other job names as needed

-- Loop through each job and check for failure or if it's disabled
DECLARE job_cursor CURSOR FOR 
SELECT job_name FROM @job_names;

OPEN job_cursor;
FETCH NEXT FROM job_cursor INTO @job_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Check if the job is enabled
    SELECT @enabled = enabled
    FROM msdb.dbo.sysjobs
    WHERE name = @job_name;

    IF @enabled = 0
    BEGIN
        -- Include server name and job name in the error message
        RAISERROR('Alert on server %s: The job %s is disabled.', 16, 1, @server_name, @job_name) WITH LOG;
    END
    ELSE
    BEGIN
        -- Get the most recent run status and time of the current job
        SELECT TOP 1 
            @last_run_status = ja.run_status,
            @last_run_time = CONVERT(DATETIME, 
                                     CONVERT(VARCHAR(8), ja.run_date, 112) + ' ' + 
                                     STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(6), ja.run_time), 6), 3, 0, ':'), 6, 0, ':'))
        FROM msdb.dbo.sysjobs j
        JOIN msdb.dbo.sysjobhistory ja ON j.job_id = ja.job_id
        WHERE j.name = @job_name
        ORDER BY ja.run_date DESC, ja.run_time DESC;

        -- Debugging: Print the last run status and time for each job
        PRINT 'Checking job: ' + @job_name;
        PRINT 'Last Run Status: ' + COALESCE(CONVERT(VARCHAR, @last_run_status), 'NULL');
        PRINT 'Last Run Time: ' + COALESCE(CONVERT(VARCHAR, @last_run_time, 120), 'NULL');

        -- Check if the last run was a failure
        IF @last_run_status = 0
        BEGIN
            -- Include server name and job name in the failure message
            RAISERROR('Alert on server %s: The last run of %s job has failed.', 16, 1, @server_name, @job_name) WITH LOG;
        END
        ELSE
        BEGIN
            PRINT 'The last run of ' + @job_name + ' job was successful.';
        END;
    END

    FETCH NEXT FROM job_cursor INTO @job_name;
END

CLOSE job_cursor;
DEALLOCATE job_cursor;
