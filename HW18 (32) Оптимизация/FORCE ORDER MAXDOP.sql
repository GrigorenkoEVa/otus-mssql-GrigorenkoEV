set statistics io, time on;

--original
Select ord.CustomerID, det.StockItemID, 
SUM(det.UnitPrice), 
SUM(det.Quantity), 
COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID

WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId FROM Warehouse.StockItems AS It Where It.StockItemID = det.StockItemID) = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity) FROM Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
		WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID


--В плане выполнения стоимость дороже оригинала, но 
--оригинал Время ЦП = 593 мс, затраченное время = 781 мс.
-- Время ЦП = 547 мс, затраченное время = 794 мс.
Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID) 
FROM Sales.Orders AS ord 
JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID 
JOIN Sales.Invoices AS Inv ON Inv.BillToCustomerID != ord.CustomerID --условия соединения с Sales.Invoices перенесены в join 
             AND DATEDIFF (dd , Inv.InvoiceDate , ord.OrderDate) = 0 
			 AND Inv.OrderID = ord.OrderID 
JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID 
JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID 
WHERE (Select SupplierId FROM Warehouse.StockItems AS It Where It.StockItemID = det.StockItemID) = 12 
   AND (SELECT SUM(Total.UnitPrice*Total.Quantity) FROM Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
		WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
 GROUP BY ord.CustomerID, det.StockItemID 
 ORDER BY ord.CustomerID, det.StockItemID 
OPTION (FORCE ORDER, MAXDOP 1) --попытаемся обработать таблицы в порядке перечисления
