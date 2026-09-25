SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Dropping foreign keys from [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [FK_Products_Categories]
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [FK_Products_Suppliers]
GO
PRINT N'Dropping foreign keys from [dbo].[CustomerCustomerDemo]'
GO
ALTER TABLE [dbo].[CustomerCustomerDemo] DROP CONSTRAINT [FK_CustomerCustomerDemo_Customers]
GO
ALTER TABLE [dbo].[CustomerCustomerDemo] DROP CONSTRAINT [FK_CustomerCustomerDemo]
GO
PRINT N'Dropping foreign keys from [dbo].[Orders]'
GO
ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [FK_Orders_Customers]
GO
ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [FK_Orders_Employees]
GO
ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [FK_Orders_Shippers]
GO
PRINT N'Dropping foreign keys from [dbo].[EmployeeTerritories]'
GO
ALTER TABLE [dbo].[EmployeeTerritories] DROP CONSTRAINT [FK_EmployeeTerritories_Employees]
GO
ALTER TABLE [dbo].[EmployeeTerritories] DROP CONSTRAINT [FK_EmployeeTerritories_Territories]
GO
PRINT N'Dropping foreign keys from [dbo].[Employees]'
GO
ALTER TABLE [dbo].[Employees] DROP CONSTRAINT [FK_Employees_Employees]
GO
PRINT N'Dropping foreign keys from [dbo].[Order Details]'
GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [FK_Order_Details_Orders]
GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [FK_Order_Details_Products]
GO
PRINT N'Dropping foreign keys from [dbo].[Territories]'
GO
ALTER TABLE [dbo].[Territories] DROP CONSTRAINT [FK_Territories_Region]
GO
PRINT N'Dropping constraints from [dbo].[Employees]'
GO
ALTER TABLE [dbo].[Employees] DROP CONSTRAINT [CK_Birthdate]
GO
PRINT N'Dropping constraints from [dbo].[Order Details]'
GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [CK_UnitPrice]
GO
PRINT N'Dropping constraints from [dbo].[Order Details]'
GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [CK_Quantity]
GO
PRINT N'Dropping constraints from [dbo].[Order Details]'
GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [CK_Discount]
GO
PRINT N'Dropping constraints from [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [CK_Products_UnitPrice]
GO
PRINT N'Dropping constraints from [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [CK_UnitsInStock]
GO
PRINT N'Dropping constraints from [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [CK_UnitsOnOrder]
GO
PRINT N'Dropping constraints from [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [CK_ReorderLevel]
GO
PRINT N'Dropping constraints from [dbo].[Categories]'
GO
ALTER TABLE [dbo].[Categories] DROP CONSTRAINT [PK_Categories]
GO
PRINT N'Dropping constraints from [dbo].[CustomerCustomerDemo]'
GO
ALTER TABLE [dbo].[CustomerCustomerDemo] DROP CONSTRAINT [PK_CustomerCustomerDemo]
GO
PRINT N'Dropping constraints from [dbo].[CustomerDemographics]'
GO
ALTER TABLE [dbo].[CustomerDemographics] DROP CONSTRAINT [PK_CustomerDemographics]
GO
PRINT N'Dropping constraints from [dbo].[Customers]'
GO
ALTER TABLE [dbo].[Customers] DROP CONSTRAINT [PK_Customers]
GO
PRINT N'Dropping constraints from [dbo].[EmployeeTerritories]'
GO
ALTER TABLE [dbo].[EmployeeTerritories] DROP CONSTRAINT [PK_EmployeeTerritories]
GO
PRINT N'Dropping constraints from [dbo].[Employees]'
GO
ALTER TABLE [dbo].[Employees] DROP CONSTRAINT [PK_Employees]
GO
PRINT N'Dropping constraints from [dbo].[Order Details]'
GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [PK_Order_Details]
GO
PRINT N'Dropping constraints from [dbo].[Orders]'
GO
ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [PK_Orders]
GO
PRINT N'Dropping constraints from [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [PK_Products]
GO
PRINT N'Dropping constraints from [dbo].[Region]'
GO
ALTER TABLE [dbo].[Region] DROP CONSTRAINT [PK_Region]
GO
PRINT N'Dropping constraints from [dbo].[Shippers]'
GO
ALTER TABLE [dbo].[Shippers] DROP CONSTRAINT [PK_Shippers]
GO
PRINT N'Dropping constraints from [dbo].[Suppliers]'
GO
ALTER TABLE [dbo].[Suppliers] DROP CONSTRAINT [PK_Suppliers]
GO
PRINT N'Dropping constraints from [dbo].[Territories]'
GO
ALTER TABLE [dbo].[Territories] DROP CONSTRAINT [PK_Territories]
GO
PRINT N'Dropping constraints from [dbo].[Order Details]'
GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [DF_Order_Details_UnitPrice]
GO
PRINT N'Dropping constraints from [dbo].[Order Details]'
GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [DF_Order_Details_Quantity]
GO
PRINT N'Dropping constraints from [dbo].[Order Details]'
GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [DF_Order_Details_Discount]
GO
PRINT N'Dropping constraints from [dbo].[Orders]'
GO
ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [DF_Orders_Freight]
GO
PRINT N'Dropping constraints from [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [DF_Products_UnitPrice]
GO
PRINT N'Dropping constraints from [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [DF_Products_UnitsInStock]
GO
PRINT N'Dropping constraints from [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [DF_Products_UnitsOnOrder]
GO
PRINT N'Dropping constraints from [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [DF_Products_ReorderLevel]
GO
PRINT N'Dropping constraints from [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [DF_Products_Discontinued]
GO
PRINT N'Dropping index [CategoryName] from [dbo].[Categories]'
GO
DROP INDEX [CategoryName] ON [dbo].[Categories]
GO
PRINT N'Dropping index [CompanyName] from [dbo].[Customers]'
GO
DROP INDEX [CompanyName] ON [dbo].[Customers]
GO
PRINT N'Dropping index [City] from [dbo].[Customers]'
GO
DROP INDEX [City] ON [dbo].[Customers]
GO
PRINT N'Dropping index [Region] from [dbo].[Customers]'
GO
DROP INDEX [Region] ON [dbo].[Customers]
GO
PRINT N'Dropping index [PostalCode] from [dbo].[Customers]'
GO
DROP INDEX [PostalCode] ON [dbo].[Customers]
GO
PRINT N'Dropping index [LastName] from [dbo].[Employees]'
GO
DROP INDEX [LastName] ON [dbo].[Employees]
GO
PRINT N'Dropping index [PostalCode] from [dbo].[Employees]'
GO
DROP INDEX [PostalCode] ON [dbo].[Employees]
GO
PRINT N'Dropping index [OrderID] from [dbo].[Order Details]'
GO
DROP INDEX [OrderID] ON [dbo].[Order Details]
GO
PRINT N'Dropping index [OrdersOrder_Details] from [dbo].[Order Details]'
GO
DROP INDEX [OrdersOrder_Details] ON [dbo].[Order Details]
GO
PRINT N'Dropping index [ProductID] from [dbo].[Order Details]'
GO
DROP INDEX [ProductID] ON [dbo].[Order Details]
GO
PRINT N'Dropping index [ProductsOrder_Details] from [dbo].[Order Details]'
GO
DROP INDEX [ProductsOrder_Details] ON [dbo].[Order Details]
GO
PRINT N'Dropping index [CustomerID] from [dbo].[Orders]'
GO
DROP INDEX [CustomerID] ON [dbo].[Orders]
GO
PRINT N'Dropping index [CustomersOrders] from [dbo].[Orders]'
GO
DROP INDEX [CustomersOrders] ON [dbo].[Orders]
GO
PRINT N'Dropping index [EmployeeID] from [dbo].[Orders]'
GO
DROP INDEX [EmployeeID] ON [dbo].[Orders]
GO
PRINT N'Dropping index [EmployeesOrders] from [dbo].[Orders]'
GO
DROP INDEX [EmployeesOrders] ON [dbo].[Orders]
GO
PRINT N'Dropping index [OrderDate] from [dbo].[Orders]'
GO
DROP INDEX [OrderDate] ON [dbo].[Orders]
GO
PRINT N'Dropping index [ShippedDate] from [dbo].[Orders]'
GO
DROP INDEX [ShippedDate] ON [dbo].[Orders]
GO
PRINT N'Dropping index [ShippersOrders] from [dbo].[Orders]'
GO
DROP INDEX [ShippersOrders] ON [dbo].[Orders]
GO
PRINT N'Dropping index [ShipPostalCode] from [dbo].[Orders]'
GO
DROP INDEX [ShipPostalCode] ON [dbo].[Orders]
GO
PRINT N'Dropping index [ProductName] from [dbo].[Products]'
GO
DROP INDEX [ProductName] ON [dbo].[Products]
GO
PRINT N'Dropping index [SupplierID] from [dbo].[Products]'
GO
DROP INDEX [SupplierID] ON [dbo].[Products]
GO
PRINT N'Dropping index [SuppliersProducts] from [dbo].[Products]'
GO
DROP INDEX [SuppliersProducts] ON [dbo].[Products]
GO
PRINT N'Dropping index [CategoriesProducts] from [dbo].[Products]'
GO
DROP INDEX [CategoriesProducts] ON [dbo].[Products]
GO
PRINT N'Dropping index [CategoryID] from [dbo].[Products]'
GO
DROP INDEX [CategoryID] ON [dbo].[Products]
GO
PRINT N'Dropping index [CompanyName] from [dbo].[Suppliers]'
GO
DROP INDEX [CompanyName] ON [dbo].[Suppliers]
GO
PRINT N'Dropping index [PostalCode] from [dbo].[Suppliers]'
GO
DROP INDEX [PostalCode] ON [dbo].[Suppliers]
GO
PRINT N'Dropping [dbo].[SalesByCategory]'
GO
DROP PROCEDURE [dbo].[SalesByCategory]
GO
PRINT N'Dropping [dbo].[CustOrderHist]'
GO
DROP PROCEDURE [dbo].[CustOrderHist]
GO
PRINT N'Dropping [dbo].[CustOrdersOrders]'
GO
DROP PROCEDURE [dbo].[CustOrdersOrders]
GO
PRINT N'Dropping [dbo].[CustOrdersDetail]'
GO
DROP PROCEDURE [dbo].[CustOrdersDetail]
GO
PRINT N'Dropping [dbo].[Sales by Year]'
GO
DROP PROCEDURE [dbo].[Sales by Year]
GO
PRINT N'Dropping [dbo].[Employee Sales by Country]'
GO
DROP PROCEDURE [dbo].[Employee Sales by Country]
GO
PRINT N'Dropping [dbo].[Ten Most Expensive Products]'
GO
DROP PROCEDURE [dbo].[Ten Most Expensive Products]
GO
PRINT N'Dropping [dbo].[Summary of Sales by Year]'
GO
DROP VIEW [dbo].[Summary of Sales by Year]
GO
PRINT N'Dropping [dbo].[Summary of Sales by Quarter]'
GO
DROP VIEW [dbo].[Summary of Sales by Quarter]
GO
PRINT N'Dropping [dbo].[Sales Totals by Amount]'
GO
DROP VIEW [dbo].[Sales Totals by Amount]
GO
PRINT N'Dropping [dbo].[Sales by Category]'
GO
DROP VIEW [dbo].[Sales by Category]
GO
PRINT N'Dropping [dbo].[Category Sales for 1997]'
GO
DROP VIEW [dbo].[Category Sales for 1997]
GO
PRINT N'Dropping [dbo].[Product Sales for 1997]'
GO
DROP VIEW [dbo].[Product Sales for 1997]
GO
PRINT N'Dropping [dbo].[Order Subtotals]'
GO
DROP VIEW [dbo].[Order Subtotals]
GO
PRINT N'Dropping [dbo].[Order Details Extended]'
GO
DROP VIEW [dbo].[Order Details Extended]
GO
PRINT N'Dropping [dbo].[Invoices]'
GO
DROP VIEW [dbo].[Invoices]
GO
PRINT N'Dropping [dbo].[Quarterly Orders]'
GO
DROP VIEW [dbo].[Quarterly Orders]
GO
PRINT N'Dropping [dbo].[Products by Category]'
GO
DROP VIEW [dbo].[Products by Category]
GO
PRINT N'Dropping [dbo].[Products Above Average Price]'
GO
DROP VIEW [dbo].[Products Above Average Price]
GO
PRINT N'Dropping [dbo].[Orders Qry]'
GO
DROP VIEW [dbo].[Orders Qry]
GO
PRINT N'Dropping [dbo].[Current Product List]'
GO
DROP VIEW [dbo].[Current Product List]
GO
PRINT N'Dropping [dbo].[Alphabetical list of products]'
GO
DROP VIEW [dbo].[Alphabetical list of products]
GO
PRINT N'Dropping [dbo].[Customer and Suppliers by City]'
GO
DROP VIEW [dbo].[Customer and Suppliers by City]
GO
PRINT N'Dropping [dbo].[Region]'
GO
DROP TABLE [dbo].[Region]
GO
PRINT N'Dropping [dbo].[Suppliers]'
GO
DROP TABLE [dbo].[Suppliers]
GO
PRINT N'Dropping [dbo].[Categories]'
GO
DROP TABLE [dbo].[Categories]
GO
PRINT N'Dropping [dbo].[Shippers]'
GO
DROP TABLE [dbo].[Shippers]
GO
PRINT N'Dropping [dbo].[Products]'
GO
DROP TABLE [dbo].[Products]
GO
PRINT N'Dropping [dbo].[Order Details]'
GO
DROP TABLE [dbo].[Order Details]
GO
PRINT N'Dropping [dbo].[Orders]'
GO
DROP TABLE [dbo].[Orders]
GO
PRINT N'Dropping [dbo].[Territories]'
GO
DROP TABLE [dbo].[Territories]
GO
PRINT N'Dropping [dbo].[EmployeeTerritories]'
GO
DROP TABLE [dbo].[EmployeeTerritories]
GO
PRINT N'Dropping [dbo].[Employees]'
GO
DROP TABLE [dbo].[Employees]
GO
PRINT N'Dropping [dbo].[Customers]'
GO
DROP TABLE [dbo].[Customers]
GO
PRINT N'Dropping [dbo].[CustomerCustomerDemo]'
GO
DROP TABLE [dbo].[CustomerCustomerDemo]
GO
PRINT N'Dropping [dbo].[CustomerDemographics]'
GO
DROP TABLE [dbo].[CustomerDemographics]
GO

