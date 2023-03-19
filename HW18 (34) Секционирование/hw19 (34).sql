select distinct t.name
from sys.partitions p
inner join sys.tables t
on p.object_id = t.object_id
where p.partition_number <> 1

select $partition.fnYearPartition (s_date) as partition,
		count (*) as count,
		min (s_date),
		max (s_date)
from rights
group by $partition.fnYearPartition (s_date);

----------------------------------------------------------
alter database ReestrRP add filegroup YearData;

ALTER DATABASE ReestrRP ADD FILE 
(   NAME = N'Years',
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQL2019\MSSQL\DATA\ReestrRPearData.ndf',
    SIZE = 5MB, FILEGROWTH = 5MB ) TO FILEGROUP YearData;

create partition function fnYearPartition (date) as range right
for values ('20100101', '20150101', '20200101');

create partition scheme schmYearPartition as partition fnYearPartition all to ([YearData]);

select * into rightsPartitioned from rights;

CREATE CLUSTERED INDEX CIX_rightsPartitioned_s_date ON rightsPartitioned (s_date);