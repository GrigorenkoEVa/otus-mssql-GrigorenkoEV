/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

select * from
Sales.Invoices
where InvoiceDate BETWEEN '2015-07-04' AND '2015-07-05';

SELECT
	PersonId, 
	FullName 
		 
FROM Application.People
WHERE IsSalesperson = 1
and (SELECT 
			COUNT(InvoiceId) AS SalesCount
		FROM Sales.Invoices
		WHERE Invoices.SalespersonPersonID = Application.People.PersonID
		and InvoiceDate BETWEEN '2015-07-04' AND '2015-07-05'
	 ) = 0;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
/*
SELECT 
	StockItemID, 
	StockItemName, 
	UnitPrice, 
	(SELECT 
		min(UnitPrice) 
	FROM Warehouse.StockItems) AS MinPrice
FROM Warehouse.StockItems;
*/

SELECT 
	StockItemID, 
	StockItemName, 
	UnitPrice--, 
	--(SELECT	min(UnitPrice) 	FROM Warehouse.StockItems) AS MinPrice
FROM Warehouse.StockItems
WHERE UnitPrice = (SELECT min(UnitPrice) FROM Warehouse.StockItems);

SELECT 
	StockItemID, 
	StockItemName, 
	UnitPrice
FROM Warehouse.StockItems
WHERE UnitPrice = (SELECT top 1 (UnitPrice) FROM Warehouse.StockItems order by UnitPrice);


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

/*
select ct.CustomerID, ct.TransactionAmount,
(select max (ct.TransactionAmount) from Sales.CustomerTransactions ct)
from Sales.CustomerTransactions ct order by ct.TransactionAmount desc;
*/

select top 5
ct.CustomerID, c.CustomerName, ct.TransactionAmount
from Sales.CustomerTransactions ct
join Sales.Customers c on c.CustomerID = ct.CustomerID
order by ct.TransactionAmount desc;

--CTE
with cte as
(select top 5 TransactionAmount from Sales.CustomerTransactions order by TransactionAmount desc)
select ct.CustomerID, c.CustomerName, ct.TransactionAmount
from Sales.Customers c
join Sales.CustomerTransactions ct on c.CustomerID = ct.CustomerID
join cte on ct.TransactionAmount = cte.TransactionAmount


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/


select 
ac.CityID, ac.CityName, sol.UnitPrice, ap.FullName
from Sales.Customers sc
join Sales.Orders so on so.CustomerID = sc.CustomerID
join Application.Cities ac on sc.DeliveryCityID = ac.CityID
join Sales.Invoices si ON si.OrderID = so.OrderID
join  Sales.OrderLines sol on sol.OrderID = so.OrderID
join Application.People ap on si.PackedByPersonID = ap.PersonID
where sol.UnitPrice in
(select distinct top 3 UnitPrice from Sales.OrderLines
order by  UnitPrice desc
);

--CTE
with solCTE (UnitPrice) as
(select distinct top 3 UnitPrice from Sales.OrderLines
order by UnitPrice desc
)
select 
ac.CityID, ac.CityName, sol.UnitPrice, ap.FullName
from Sales.Customers sc
join Sales.Orders so on so.CustomerID = sc.CustomerID
join Application.Cities ac on sc.DeliveryCityID = ac.CityID
join Sales.Invoices si ON si.OrderID = so.OrderID
join  Sales.OrderLines sol on sol.OrderID = so.OrderID
join Application.People ap on si.PackedByPersonID = ap.PersonID
join solCTE on sol.UnitPrice = solCTE.UnitPrice;


-----------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
