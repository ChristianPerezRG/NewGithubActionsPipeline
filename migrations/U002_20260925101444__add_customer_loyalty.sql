SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Dropping foreign keys from [dbo].[CustomerLoyaltyLog]'
GO
ALTER TABLE [dbo].[CustomerLoyaltyLog] DROP CONSTRAINT [FK_CustomerLoyaltyLog_Customers]
GO
PRINT N'Dropping constraints from [dbo].[CustomerLoyaltyLog]'
GO
ALTER TABLE [dbo].[CustomerLoyaltyLog] DROP CONSTRAINT [PK_CustomerLoyaltyLog]
GO
PRINT N'Dropping constraints from [dbo].[CustomerLoyaltyLog]'
GO
ALTER TABLE [dbo].[CustomerLoyaltyLog] DROP CONSTRAINT [DF_CustomerLoyaltyLog_ChangedAtUtc]
GO
PRINT N'Dropping constraints from [dbo].[Customers]'
GO
ALTER TABLE [dbo].[Customers] DROP CONSTRAINT [DF_Customers_LoyaltyTier]
GO
PRINT N'Dropping index [IX_CustomerLoyaltyLog_CustomerID] from [dbo].[CustomerLoyaltyLog]'
GO
DROP INDEX [IX_CustomerLoyaltyLog_CustomerID] ON [dbo].[CustomerLoyaltyLog]
GO
PRINT N'Dropping [dbo].[CustomerLoyaltyLog]'
GO
DROP TABLE [dbo].[CustomerLoyaltyLog]
GO
PRINT N'Altering [dbo].[Customers]'
GO
ALTER TABLE [dbo].[Customers] DROP
COLUMN [LoyaltyTier]
GO
PRINT N'Refreshing [dbo].[Customer and Suppliers by City]'
GO
EXEC sp_refreshview N'[dbo].[Customer and Suppliers by City]'
GO
PRINT N'Refreshing [dbo].[Invoices]'
GO
EXEC sp_refreshview N'[dbo].[Invoices]'
GO
PRINT N'Refreshing [dbo].[Orders Qry]'
GO
EXEC sp_refreshview N'[dbo].[Orders Qry]'
GO
PRINT N'Refreshing [dbo].[Quarterly Orders]'
GO
EXEC sp_refreshview N'[dbo].[Quarterly Orders]'
GO
PRINT N'Refreshing [dbo].[Sales Totals by Amount]'
GO
EXEC sp_refreshview N'[dbo].[Sales Totals by Amount]'
GO

