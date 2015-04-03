USE DISASTERS
GO

-- Cannot create index on Varchar(Max) Columns

CREATE TABLE SomeTable  (
  Max_Varchar_Column VARCHAR(MAX) NULL,
  Max_Nvarchar_Column NVARCHAR(MAX) NULL,
  Varchar_Column VARCHAR(25) NULL
)
GO

INSERT INTO SomeTable VALUES ('Value1', N'Value1', 'Value1')
INSERT INTO SomeTable VALUES ('Value2', N'Value2', 'Value2')
INSERT INTO SomeTable VALUES ('Value3', N'Value3', 'Value3')
GO

SELECT * FROM SomeTable

CREATE NONCLUSTERED INDEX idx_SomeTable__Max_Varchar_Column 
  ON SomeTable (Max_Varchar_Column)
GO

CREATE NONCLUSTERED INDEX idx_SomeTable__Max_varchar_Column 
  ON SomeTable (Max_Nvarchar_Column)
GO

CREATE NONCLUSTERED INDEX idx_SomeTable__Varchar_Column 
  ON SomeTable (Varchar_Column)
GO

DROP TABLE SomeTable
GO

-- Date Comparison

DECLARE @current_datetime as DateTime2
SET @current_datetime = SYSDATETIME()

select CAST(@current_datetime AS DateTime2)

select CAST(@current_datetime AS DateTime2(3))

select CAST(@current_datetime AS DateTime)

select CAST(@current_datetime AS SMALLDATETIME)

GO

/*
ALTER TABLE StackOverflow.Posts
ADD CONSTRAINT FK_Posts__OwnerUserId FOREIGN KEY (OwnerUserId)
    REFERENCES StackOverflow.Users (Id) ;
GO

INSERT INTO StackOverflow.Users
SELECT TOP 500 * FROM StackOverflow_Aug2011..Users
GO

INSERT INTO StackOverflow.Posts
SELECT p.* FROM StackOverflow_Aug2011..Posts p
JOIN StackOverflow.Users u ON p.OwnerUserId = u.Id
GO

ALTER TABLE StackOverflow.Posts ADD CONSTRAINT PK_Posts__Id PRIMARY KEY CLUSTERED (Id)

DROP INDEX idx_Posts__OwnerUserId ON StackOverflow.Posts
GO
DROP INDEX idx_Posts__OwnerUserId_Include ON StackOverflow.Posts 
GO
ALTER TABLE StackOverflow.Posts DROP CONSTRAINT FK_Posts__OwnerUserId 
GO
*/

/*
 * FK Indexes
 */

DBCC DROPCLEANBUFFERS -- Remove pages out of buffer pool

SELECT p.Id, p.Title, u.Id, u.DisplayName
FROM   StackOverflow.Posts p
JOIN   StackOverflow.Users u on p.OwnerUserId = u.Id
WHERE  u.Id = 300 -- 333082 -- cecilphillip

ALTER TABLE StackOverflow.Posts
ADD CONSTRAINT FK_Posts__OwnerUserId FOREIGN KEY (OwnerUserId)
    REFERENCES StackOverflow.Users (Id) ;
GO

-- Is it faster?
DBCC DROPCLEANBUFFERS

SELECT p.Id, p.Title, u.Id, u.DisplayName
FROM   StackOverflow.Posts p
JOIN   StackOverflow.Users u on p.OwnerUserId = u.Id
WHERE  u.Id = 300
GO

CREATE NONCLUSTERED INDEX idx_Posts__OwnerUserId
  ON StackOverflow.Posts (OwnerUserId)
GO

-- Is an index faster?
DBCC DROPCLEANBUFFERS

SELECT p.Id, p.Title, u.Id, u.DisplayName
FROM   StackOverflow.Posts p
JOIN   StackOverflow.Users u on p.OwnerUserId = u.Id
WHERE  u.Id = 300
GO

CREATE NONCLUSTERED INDEX idx_Posts__OwnerUserId_Include
  ON StackOverflow.Posts (OwnerUserId) 
  INCLUDE (Title)
GO

DBCC DROPCLEANBUFFERS

SELECT p.Id, p.Title, u.Id, u.DisplayName
FROM   StackOverflow.Posts p
JOIN   StackOverflow.Users u on p.OwnerUserId = u.Id
WHERE  u.Id = 300
GO


-- EAV
/*
CREATE SCHEMA eav 
GO

CREATE TABLE eav.Person_Attribute(
    Attribute_Id         int             IDENTITY(1,1),
    Person_ID            int             NOT NULL,
    Attribute_Type_ID    int             NOT NULL,
    Value                varchar(max)    NULL,
    CONSTRAINT PK9 PRIMARY KEY CLUSTERED (Attribute_Id)
)

CREATE TABLE eav.Attribute_Type(
    Attribute_Type_ID    int            IDENTITY(1,1),
    Attribute_Name       varchar(50)    NULL,
    CONSTRAINT PK10 PRIMARY KEY CLUSTERED (Attribute_Type_ID)
)

CREATE TABLE eav.[Person](
    Person_ID    int    IDENTITY(1,1),
    Name         VARCHAR(50) NOT NULL
    CONSTRAINT PK8 PRIMARY KEY CLUSTERED (Person_ID)
)

ALTER TABLE eav.Person_Attribute ADD CONSTRAINT FK_Person_Attribute__Attribute_Type_ID 
    FOREIGN KEY (Attribute_Type_ID)
    REFERENCES eav.Attribute_Type(Attribute_Type_ID)

ALTER TABLE eav.Person_Attribute ADD CONSTRAINT FK_Person_Attribute__Person_ID 
    FOREIGN KEY (Person_ID)
    REFERENCES eav.[Person](Person_ID)

INSERT INTO eav.Attribute_Type (Attribute_Name) VALUES ('Birthdate')
INSERT INTO eav.Attribute_Type (Attribute_Name) VALUES ('Age')
INSERT INTO eav.Attribute_Type (Attribute_Name) VALUES ('Phone_Number')

INSERT INTO eav.[Person]  (Name) VALUES ('Cecil Phillip')
INSERT INTO eav.[Person]  (Name) VALUES ('Dave Nicholas')

INSERT INTO eav.Person_Attribute (Attribute_Type_ID, Person_ID, Value) VALUES (1, 1, '2/9/1982')
INSERT INTO eav.Person_Attribute (Attribute_Type_ID, Person_ID, Value) VALUES (2, 1, '30')
INSERT INTO eav.Person_Attribute (Attribute_Type_ID, Person_ID, Value) VALUES (3, 1, '305-555-9607')
INSERT INTO eav.Person_Attribute (Attribute_Type_ID, Person_ID, Value) VALUES (1, 2, '9/2/1983')
INSERT INTO eav.Person_Attribute (Attribute_Type_ID, Person_ID, Value) VALUES (2, 2, '29')
*/

SELECT * FROM eav.Attribute_Type
SELECT * FROM eav.Person
SELECT * from eav.Person_Attribute
GO

-- Put Person into one row
SELECT    p.Name,
          fon.value AS 'Phone_Number',
          age.value AS 'Age',
          bd.value AS 'Birthdate'
FROM      eav.Person p
LEFT JOIN eav.Person_Attribute fon  ON  p.Person_ID = fon.Person_ID
                                    AND fon.Attribute_Type_ID = 3 -- Phone_Number
LEFT JOIN eav.Person_Attribute age  ON  p.Person_ID = age.Person_ID
                                    AND age.Attribute_Type_ID = 2 -- Age
LEFT JOIN eav.Person_Attribute bd   ON  p.Person_ID = bd.Person_ID
                                    AND bd.Attribute_Type_ID = 1 -- Birthdate
;

-- Pivot Query

SELECT Name, Phone_Number, Age, Birthdate
FROM (
  SELECT at.Attribute_Name, p.Name, pa.Value 
  FROM   eav.Person_Attribute pa
  JOIN   eav.Attribute_Type   at  ON pa.Attribute_Type_ID = at.Attribute_Type_ID
  JOIN   eav.Person           p   ON pa.Person_ID = p.Person_ID) pat
PIVOT (MIN(Value) FOR Attribute_Name IN (Phone_Number, Age, Birthdate)) AS pvt
;

/*
  GUID PK
  
  CREATE SCHEMA guidpk

CREATE TABLE guidpk.IntPK (
  IntegerPK INTEGER NOT NULL
  CONSTRAINT PK_IntPK__IntegerPK PRIMARY KEY CLUSTERED (IntegerPK)
  )

CREATE TABLE guidpk.GuidPK (
  GuidPK UNIQUEIDENTIFIER NOT NULL
  CONSTRAINT PK_GuidPK__GuidPK PRIMARY KEY CLUSTERED (GuidPK)
  )

CREATE TABLE guidpk.GuidSeqPK (
  GuidSeqPK UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID()
  CONSTRAINT PK_GuidPK__GuidSeqPK PRIMARY KEY CLUSTERED (GuidSeqPK)
  )

Declare @p_NumberOfRows Bigint
Select @p_NumberOfRows=1000000;

With Base As
(
  Select 1 as n
  Union All
  Select n+1 From Base Where n < Ceiling(SQRT(@p_NumberOfRows))
),
Expand As
(
  Select 1 as C
  From Base as B1, Base as B2
),
Nums As
(
  Select Row_Number() OVER(ORDER BY C) As n
  From Expand
)
INSERT INTO guidpk.IntPK
Select n from Nums Where n<=@p_NumberOfRows

OPTION (MaxRecursion 0);

INSERT INTO guidpk.GuidPK VALUES (NEWID())
GO 1000000
-- 14:41

INSERT INTO guidpk.GuidSeqPK DEFAULT VALUES
GO 1000000
-- 11:58

*/


/*
 * Guid PK
 */

SELECT TOP 50 * FROM guidpk.GuidPK 

SELECT COUNT(*) FROM guidpk.IntPK

SELECT COUNT(*) FROM guidpk.GuidPK

sp_spaceused 'guidpk.IntPK'
GO
sp_spaceused 'guidpk.GuidPK'
GO

SELECT OBJECT_NAME(OBJECT_ID), index_id, index_type_desc, index_level,
       avg_fragmentation_in_percent, avg_page_space_used_in_percent, page_count
FROM sys.dm_db_index_physical_stats (DB_ID(N'Disasters'), OBJECT_ID(N'guidpk.IntPK'), NULL, NULL , 'SAMPLED')

SELECT OBJECT_NAME(OBJECT_ID), index_id, index_type_desc, index_level,
       avg_fragmentation_in_percent, avg_page_space_used_in_percent, page_count
FROM sys.dm_db_index_physical_stats (DB_ID(N'Disasters'), OBJECT_ID(N'guidpk.GuidPK'), NULL, NULL , 'SAMPLED')


SELECT TOP 50 * from guidpk.GuidSeqPK


sp_spaceused 'guidpk.IntPK'
GO
sp_spaceused 'guidpk.GuidPK'
GO
sp_spaceused 'guidpk.GuidSeqPK'
GO


SELECT OBJECT_NAME(OBJECT_ID), index_id, index_type_desc, index_level,
       avg_fragmentation_in_percent, avg_page_space_used_in_percent, page_count
FROM sys.dm_db_index_physical_stats (DB_ID(N'Disasters'), OBJECT_ID(N'guidpk.IntPK'), NULL, NULL , 'SAMPLED')

SELECT OBJECT_NAME(OBJECT_ID), index_id, index_type_desc, index_level,
       avg_fragmentation_in_percent, avg_page_space_used_in_percent, page_count
FROM sys.dm_db_index_physical_stats (DB_ID(N'Disasters'), OBJECT_ID(N'guidpk.GuidPK'), NULL, NULL , 'SAMPLED')

SELECT OBJECT_NAME(OBJECT_ID), index_id, index_type_desc, index_level,
       avg_fragmentation_in_percent, avg_page_space_used_in_percent, page_count
FROM sys.dm_db_index_physical_stats (DB_ID(N'Disasters'), OBJECT_ID(N'guidpk.GuidSeqPK'), NULL, NULL , 'SAMPLED')


-- Surrogate Key / No AK

-- DROP TABLE ak.Phone_Number

CREATE TABLE ak.Phone_Number (
  Phone_Number_ID  INTEGER      NOT NULL IDENTITY(1,1),
  User_ID          VARCHAR(20)      NOT NULL ,
  Phone_Number     VARCHAR(20)  NOT NULL
  CONSTRAINT PK_Phone_Number__Phone_Number_ID 
    PRIMARY KEY CLUSTERED (Phone_Number_ID)
)

INSERT INTO ak.Phone_Number (User_ID, Phone_Number)
VALUES ('Jenny', '305-867-5309') ,
       ('Plug2', '222-222-2222')

SELECT * FROM ak.Phone_Number

INSERT INTO ak.Phone_Number (User_ID, Phone_Number)
VALUES ('Jenny', '305-867-5309')

SELECT * FROM ak.Phone_Number

TRUNCATE TABLE ak.Phone_Number

ALTER TABLE ak.Phone_Number ADD CONSTRAINT AK_Phone_Number__User_ID_Phone_Number
  UNIQUE (User_ID, Phone_Number)

INSERT INTO ak.Phone_Number (User_ID, Phone_Number)
VALUES ('Jenny', '305-867-5309') ,
       ('Plug2', '222-222-2222')

SELECT * FROM ak.Phone_Number

INSERT INTO ak.Phone_Number (User_ID, Phone_Number)
VALUES ('Jenny', '305-867-5309')


-- DROP TABLE ak.Phone_Number

