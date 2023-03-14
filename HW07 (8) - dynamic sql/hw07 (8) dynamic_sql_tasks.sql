/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

--USE WideWorldImporters

/*

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

declare @dml as nvarchar(max)
declare @colname as nvarchar(max)

select @colname = isnull (@colname + ',','') + QUOTENAME(CNames)
from (select CustomerName cnames
from sales.Customers) as CNames
order by cnames

select @colname as colname

set @dml = 
N'select InvoiceMonth,'+ @colname +'
from (select 	FORMAT(DATEFROMPARTS(year(ord.OrderDate),month(ord.OrderDate),''01'') , ''dd.MM.yyyy'') as InvoiceMonth,
		CustomerName, count (ord.OrderID) as cnt
from Sales.Orders ord, Sales.Customers cust
where cust.CustomerID=ord.CustomerID
group by ord.OrderDate,cust.CustomerName
) as s
PIVOT
(   count(cnt)
    FOR CustomerName IN ('+ @colname +')
) AS pvt
order by InvoiceMonth';

exec sp_executesql @dml
