SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/*
    V002 - Customer loyalty tiers.

    Adds a LoyaltyTier column to Customers, backfills it from order history,
    and adds an audit table recording tier changes.

    Paired undo: U002_20260925091500__UNDO-add_customer_loyalty.sql
*/

PRINT N'V002: adding LoyaltyTier to dbo.Customers'
GO

ALTER TABLE dbo.Customers
    ADD LoyaltyTier NVARCHAR(20) NULL
        CONSTRAINT DF_Customers_LoyaltyTier DEFAULT (N'Standard')
GO

PRINT N'V002: creating dbo.CustomerLoyaltyLog'
GO

CREATE TABLE dbo.CustomerLoyaltyLog
(
    LoyaltyLogID  INT IDENTITY(1,1)   NOT NULL,
    CustomerID    NCHAR(5)            NOT NULL,
    PreviousTier  NVARCHAR(20)        NULL,
    NewTier       NVARCHAR(20)        NOT NULL,
    ChangedAtUtc  DATETIME2(0)        NOT NULL
        CONSTRAINT DF_CustomerLoyaltyLog_ChangedAtUtc DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_CustomerLoyaltyLog PRIMARY KEY CLUSTERED (LoyaltyLogID),
    CONSTRAINT FK_CustomerLoyaltyLog_Customers FOREIGN KEY (CustomerID)
        REFERENCES dbo.Customers (CustomerID)
)
GO

CREATE NONCLUSTERED INDEX IX_CustomerLoyaltyLog_CustomerID
    ON dbo.CustomerLoyaltyLog (CustomerID)
GO

PRINT N'V002: backfilling tiers from order history'
GO

-- Existing customers are graded on how many orders they have placed.
-- New rows pick up 'Standard' from the default constraint.
UPDATE c
SET c.LoyaltyTier =
        CASE
            WHEN o.OrderCount >= 20 THEN N'Gold'
            WHEN o.OrderCount >= 10 THEN N'Silver'
            ELSE N'Standard'
        END
FROM dbo.Customers AS c
INNER JOIN
(
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM dbo.Orders
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
) AS o
    ON o.CustomerID = c.CustomerID
GO

UPDATE dbo.Customers
SET LoyaltyTier = N'Standard'
WHERE LoyaltyTier IS NULL
GO

ALTER TABLE dbo.Customers
    ALTER COLUMN LoyaltyTier NVARCHAR(20) NOT NULL
GO

-- Record the backfill so the audit table is not empty on a fresh build.
INSERT INTO dbo.CustomerLoyaltyLog (CustomerID, PreviousTier, NewTier)
SELECT CustomerID, NULL, LoyaltyTier
FROM dbo.Customers
GO

PRINT N'V002: refreshing views over dbo.Customers'
GO

-- These views select from Customers, so their cached column metadata is stale.
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

PRINT N'V002: complete'
GO
