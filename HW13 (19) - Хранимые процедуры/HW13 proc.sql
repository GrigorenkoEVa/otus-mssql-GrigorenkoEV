
/*
1.�������� ������� ������������ ������� � ���������� ������ �������.
*/

CREATE FUNCTION dbo.MaxPrice (@Param int)
RETURNS TABLE 
AS
	RETURN   
(  
select top (@Param) c.CustomerID, c.CustomerName, i.InvoiceDate, il.ExtendedPrice
from 
Sales.Customers c
INNER JOIN Sales.Invoices i on c.CustomerID = i.CustomerID
INNER JOIN Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
inner join (select MAX (ExtendedPrice) e from Sales.InvoiceLines) m on m.e=il.ExtendedPrice
);  
GO    

SELECT * FROM dbo.MaxPrice (10); 
GO

/*
2.�������� �������� ��������� � �������� ���������� �ustomerID, ��������� ����� ������� �� ����� �������. 
������������ ������� :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE PROCEDURE TSum ( 
@CustomerID int = NULL 
)
AS   
    SET NOCOUNT ON;   

IF @CustomerID IS NULL  
	BEGIN  
	   PRINT N'������: ��������� �������� �ustomerID.'  
	   RETURN  -- �� ������������ ������ ���. ������� ��������
	END     
-- ���������� ��������� ��������� output parameter.  
select c.CustomerID, c.CustomerName, i.InvoiceDate, il.ExtendedPrice
from 
Sales.Customers c
INNER JOIN Sales.Invoices i on c.CustomerID = i.CustomerID
INNER JOIN Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
where c.CustomerID = @CustomerID

-- �������������� ������� �������� �� �������� ��������� �������� Return	   
RETURN  
GO  

--2 ������ ��������� � �������� ����������.  
EXEC TSum @CustomerID = 818;  
GO  

/*
3.������� ���������� ������� � �������� ���������, ���������� � ��� ������� � ������������������ � ������.
*/

DROP PROCEDURE [dbo].[POrder]
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE POrder ( 
@DtBegin date = '1900-01-01',
@DtEnd date = '1900-01-01'
)
AS   
    SET NOCOUNT ON;   
 
IF @DtBegin = '1900-01-01' or @DtEnd = '1900-01-01'
	BEGIN  
	   PRINT N'������: ��������� ������ ��� ����.'  
	   RETURN 
	END     
  
select met.DeliveryMethodName,
format(pord.ExpectedDeliveryDate,'dd.MM.yyyy') as ExpectedDeliveryDate,
sup.SupplierName,
people.FullName
from Purchasing.Suppliers sup, Purchasing.PurchaseOrders pord, Application.DeliveryMethods met, Application.People people
where sup.SupplierID = pord.SupplierID
and sup.DeliveryMethodID = met.DeliveryMethodID
and pord.ContactPersonID = people.PersonID
and pord.ExpectedDeliveryDate BETWEEN  @DtBegin AND  @DtEnd
and pord.IsOrderFinalized = 1

RETURN  
GO  

EXEC POrder @DtBegin='01.01.2013', @DtEnd='01.02.2013' 
GO  
----------------------------------------------------------------------------------

CREATE FUNCTION dbo.FOrder (@DtBegin date,
							  @DtEnd date)
RETURNS TABLE 
AS
	RETURN   
(  
select met.DeliveryMethodName,
format(pord.ExpectedDeliveryDate,'dd.MM.yyyy') as ExpectedDeliveryDate,
sup.SupplierName,
people.FullName
from Purchasing.Suppliers sup, Purchasing.PurchaseOrders pord, Application.DeliveryMethods met, Application.People people
where sup.SupplierID = pord.SupplierID
and sup.DeliveryMethodID = met.DeliveryMethodID
and pord.ContactPersonID = people.PersonID
and pord.ExpectedDeliveryDate BETWEEN  @DtBegin AND  @DtEnd
and pord.IsOrderFinalized = 1
);  
GO    

SELECT * FROM dbo.FOrder ('01.01.2013','01.02.2013'); 
GO
---------------------------------------------------------------------------
SET STATISTICS IO, TIME ON

EXEC POrder @DtBegin='01.01.2013', @DtEnd='01.02.2013' ;
SELECT * FROM dbo.FOrder ('01.01.2013','01.02.2013'); 

/*
4.�������� ��������� ������� �������� ��� �� ����� ������� ��� ������ ������ result set'� ��� ������������� �����.
*/

CREATE FUNCTION dbo.FCustomerFromStockItem (@Param nvarchar(100))
RETURNS TABLE 
AS
	RETURN   
(  
select distinct
	   cust.CustomerID,
	   cust.CustomerName,
	   cust.PhoneNumber
from Sales.Orders ord
INNER JOIN Sales.Customers cust ON cust.CustomerID = ord.CustomerID
INNER JOIN Sales.OrderLines ol ON ol.OrderID = ord.OrderID
INNER JOIN Warehouse.StockItems sti ON sti.StockItemID = ol.StockItemID
where sti.StockItemName = @Param
);  
GO    

SELECT * FROM dbo.FCustomerFromStockItem ('Chocolate frogs 250g'); 
GO

----------------------------
--��� ������ ������� ��� ����� ����� ������������� �������, �� ���������, ��� ������ ��������� ������� � ��������... 
CREATE PROCEDURE ProcStockItemNameCursor   
    @SINCursor CURSOR VARYING OUTPUT  
AS  
    SET NOCOUNT ON;  
    SET @SINCursor = CURSOR  
    FORWARD_ONLY STATIC FOR  
      ----??????---------------
    OPEN @SINCursor;  
GO 

DECLARE @MyCursor CURSOR; 
EXEC ProcStockItemNameCursor ('Chocolate frogs 250g') @SINCursor = @MyCursor OUTPUT;  
WHILE (@@FETCH_STATUS = 0)
BEGIN;  
     FETCH NEXT FROM @MyCursor; 
END;  
CLOSE @MyCursor;  
DEALLOCATE @MyCursor;  
GO    


/*
5.�����������. �� ���� ���������� ������� ����� ������� �������� ���������� �� �� ������������  � ������.
*/
