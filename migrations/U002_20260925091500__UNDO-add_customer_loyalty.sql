SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/*
    U002 - Reverses V002_20260925091500__add_customer_loyalty.sql

    Drops the audit table and the LoyaltyTier column, returning the schema to
    its V001 state. Objects are dropped in dependency order: the foreign key
    on CustomerLoyaltyLog references Customers, so the table goes first.
*/

PRINT N'U002: dropping dbo.CustomerLoyaltyLog'
GO

DROP TABLE IF EXISTS dbo.CustomerLoyaltyLog
GO

PRINT N'U002: dropping LoyaltyTier from dbo.Customers'
GO

-- The default constraint must go before the column it defaults.
-- Looked up by name rather than assumed, in case it was renamed.
IF EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_Customers_LoyaltyTier')
    ALTER TABLE dbo.Customers DROP CONSTRAINT DF_Customers_LoyaltyTier
GO

IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID(N'dbo.Customers') AND name = 'LoyaltyTier')
    ALTER TABLE dbo.Customers DROP COLUMN LoyaltyTier
GO

PRINT N'U002: refreshing views over dbo.Customers'
GO

EXEC sp_refreshview N'dbo.Customer and Suppliers by City'
GO
EXEC sp_refreshview N'dbo.Orders Qry'
GO
EXEC sp_refreshview N'dbo.Quarterly Orders'
GO
EXEC sp_refreshview N'dbo.Invoices'
GO
EXEC sp_refreshview N'dbo.Sales Totals by Amount'
GO

PRINT N'U002: complete'
GO
