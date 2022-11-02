/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select wsi.StockItemID, wsi.StockItemName
from Warehouse.StockItems wsi
where wsi.StockItemName like '%urgent%'
or wsi.StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

/* Как нельзя
select sup.SupplierID, sup.SupplierName
from Purchasing.Suppliers sup
where sup.SupplierID not in
(
select sup.SupplierID
from Purchasing.PurchaseOrders ord, Purchasing.Suppliers sup
where ord.SupplierID = sup.SupplierID 
)
*/

select sup.SupplierID, sup.SupplierName
from Purchasing.Suppliers sup
left join Purchasing.PurchaseOrders ord
on ord.SupplierID = sup.SupplierID
except
select sup.SupplierID, sup.SupplierName
from Purchasing.Suppliers sup
join Purchasing.PurchaseOrders ord
on ord.SupplierID = sup.SupplierID


select sup.SupplierID, sup.SupplierName
from Purchasing.Suppliers sup
left join Purchasing.PurchaseOrders ord
on ord.SupplierID = sup.SupplierID
where ord.PurchaseOrderID IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select ord.OrderID, 
format(ord.OrderDate, 'dd.MM.yyyy') as OrderDate,
--month(ord.OrderDate) as OrderMonth,
DateName( month , DateAdd( month , month(ord.OrderDate) , 0 ) - 1 ) as OrderNMonth,
DatePart(quarter, ord.OrderDate ) as OrderQuarter,
--format(ordln.PickingCompletedWhen, 'dd.MM.yyyy')as PickingCompletedWhen,
case when month(ord.OrderDate) < 5 then 1
	 when month(ord.OrderDate) > 4  and month(ord.OrderDate) < 9 then 2
else 3 end OrderThird,
custm.CustomerName,
ordln.Quantity,
ordln.UnitPrice
from Sales.Orders ord, Sales.OrderLines ordln, Sales.Customers custm
where custm.CustomerID=ord.CustomerID
and ord.OrderID=ordln.OrderID
and (ordln.UnitPrice>100 or ordln.Quantity>20)
and ordln.PickingCompletedWhen is not null
order by OrderQuarter,  OrderDate
offset 1000 ROWS FETCH FIRST 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select met.DeliveryMethodName,
format(pord.ExpectedDeliveryDate,'dd.MM.yyyy') as ExpectedDeliveryDate,
sup.SupplierName,
people.FullName
--pord.IsOrderFinalized
from Purchasing.Suppliers sup, Purchasing.PurchaseOrders pord, Application.DeliveryMethods met, Application.People people
where sup.SupplierID = pord.SupplierID
and sup.DeliveryMethodID = met.DeliveryMethodID
and pord.ContactPersonID = people.PersonID
and pord.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-02-01'
and met.DeliveryMethodName like '%Air Freight'
and pord.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10
ord.OrderID,
		ord.OrderDate,
		cust.CustomerName, 
		ppl.FullName as SalespersonName
from Sales.Orders ord, Sales.Customers cust, Application.People ppl
where ord.SalespersonPersonID=ppl.PersonID
and cust.CustomerID=ord.CustomerID
order by ord.OrderDate desc


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select distinct
	   cust.CustomerID,
	   cust.CustomerName,
	   cust.PhoneNumber
from Sales.Orders ord
INNER JOIN Sales.Customers cust ON cust.CustomerID = ord.CustomerID
INNER JOIN Sales.OrderLines ol ON ol.OrderID = ord.OrderID
INNER JOIN Warehouse.StockItems sti ON sti.StockItemID = ol.StockItemID
where sti.StockItemName = 'Chocolate frogs 250g'
order by cust.CustomerID