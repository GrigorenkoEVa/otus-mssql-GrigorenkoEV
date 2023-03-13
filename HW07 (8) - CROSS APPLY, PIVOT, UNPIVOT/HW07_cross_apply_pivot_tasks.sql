/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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

USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

SELECT *
FROM (
select 
--left(datename(month,ord.OrderDate),3)as InvoiceMonth,
--cast(ord.OrderDate as nvarchar) as InvoiceMonth,
DATEFROMPARTS(year(ord.OrderDate),month(ord.OrderDate),'01') as InvoiceMonth,
--month(ord.OrderDate) as InvoiceMonth,
		--format(ord.OrderDate, 'dd.MM.yyyy') as OrderDate,
		cust.CustomerName,
		cast(ord.IsUndersupplyBackordered as int) as num
from Sales.Orders ord, Sales.Customers cust
where cust.CustomerID=ord.CustomerID and (cust.CustomerID > 1 and cust.CustomerID < 7)
--order by cust.CustomerID
) as s
PIVOT
(   sum(num)
    --FOR CustomerName IN ('Gasport, NY', 'Jessie, ND', 'Medicine Lodge, KS', 'Peeples Valley, AZ', 'Sylvanite, MT')
	FOR CustomerName IN (NY, ND, KS, AZ, MT)
) AS pvt
order by InvoiceMonth;


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select * from
(select c.CustomerName,
c.DeliveryAddressLine1, c.DeliveryAddressLine2,
c.PostalAddressLine1, c.PostalAddressLine2
from Sales.Customers c
where c.CustomerName like 'Tailspin Toys%') as customers
UNPIVOT (AddressLine for Address in (DeliveryAddressLine1,DeliveryAddressLine2,PostalAddressLine1,PostalAddressLine2)) as unpt;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select * from
(select CountryId, CountryName, CAST(IsoAlpha3Code AS nvarchar) as IsoAl3Code, 
CAST(IsoNumericCode AS nvarchar) as IsoNCode
from Application.Countries
) as Countrs
UNPIVOT (Code for Iso in (IsoAl3Code, IsoNCode)) as unpvt;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

/*
select c.CustomerID,
c.CustomerName, (select top 1 il.UnitPrice
				from Sales.Invoices i, Sales.InvoiceLines il
				where i.InvoiceID = il.InvoiceID and i.CustomerID=c.CustomerID
				order by il.UnitPrice)
from Sales.Customers C
ORDER BY C.CustomerName;
*/

SELECT c.CustomerID,
c.CustomerName,  O.*
FROM Sales.Customers C
OUTER APPLY (select top 2 il.UnitPrice, il.StockItemID, i.InvoiceDate
				from Sales.Invoices i, Sales.InvoiceLines il
				where i.InvoiceID = il.InvoiceID and i.CustomerID=c.CustomerID
				order by il.UnitPrice) AS O
ORDER BY C.CustomerName;
