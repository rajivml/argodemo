```
DECLARE @sql NVARCHAR(max)

SELECT @sql = stuff((
			SELECT ', ' + quotename(table_schema) + '.' + quotename(table_name)
			FROM INFORMATION_SCHEMA.Tables
			WHERE table_schema = 'ai_appmanager'
AND TABLE_TYPE = 'BASE TABLE'
			ORDER BY table_name
			FOR XML path('')
			), 1, 2, '')

SET @sql = 'DROP TABLE ' + @sql

PRINT @sql

BEGIN TRANSACTION

EXECUTE (@SQL)

COMMIT


SELECT 
    'ALTER TABLE [' +  OBJECT_SCHEMA_NAME(parent_object_id) +
    '].[' + OBJECT_NAME(parent_object_id) + 
    '] DROP CONSTRAINT [' + name + ']'
FROM sys.foreign_keys
WHERE referenced_object_id = object_id('ai_appmanager.labelling_app')
```
