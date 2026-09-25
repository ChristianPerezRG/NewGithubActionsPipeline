SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Creating [dbo].[CustomerLoyaltyLog]'
GO
CREATE TABLE [dbo].[CustomerLoyaltyLog]
(
[LoyaltyLogID] [int] NOT NULL IDENTITY(1, 1),
[CustomerID] [nchar] (5) NOT NULL,
[PreviousTier] [nvarchar] (20) NULL,
[NewTier] [nvarchar] (20) NOT NULL,
[ChangedAtUtc] [datetime2] (0) NOT NULL CONSTRAINT [DF_CustomerLoyaltyLog_ChangedAtUtc] DEFAULT (sysutcdatetime())
)
GO
PRINT N'Creating primary key [PK_CustomerLoyaltyLog] on [dbo].[CustomerLoyaltyLog]'
GO
ALTER TABLE [dbo].[CustomerLoyaltyLog] ADD CONSTRAINT [PK_CustomerLoyaltyLog] PRIMARY KEY CLUSTERED ([LoyaltyLogID])
GO
PRINT N'Creating index [IX_CustomerLoyaltyLog_CustomerID] on [dbo].[CustomerLoyaltyLog]'
GO
CREATE NONCLUSTERED INDEX [IX_CustomerLoyaltyLog_CustomerID] ON [dbo].[CustomerLoyaltyLog] ([CustomerID])
GO
PRINT N'Altering [dbo].[Customers]'
GO
ALTER TABLE [dbo].[Customers] ADD
[LoyaltyTier] [nvarchar] (20) NOT NULL CONSTRAINT [DF_Customers_LoyaltyTier] DEFAULT (N'Standard')
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
PRINT N'Adding foreign keys to [dbo].[CustomerLoyaltyLog]'
GO
ALTER TABLE [dbo].[CustomerLoyaltyLog] ADD CONSTRAINT [FK_CustomerLoyaltyLog_Customers] FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customers] ([CustomerID])
GO

