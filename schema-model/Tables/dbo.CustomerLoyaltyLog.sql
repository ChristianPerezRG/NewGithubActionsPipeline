CREATE TABLE [dbo].[CustomerLoyaltyLog]
(
[LoyaltyLogID] [int] NOT NULL IDENTITY(1, 1),
[CustomerID] [nchar] (5) NOT NULL,
[PreviousTier] [nvarchar] (20) NULL,
[NewTier] [nvarchar] (20) NOT NULL,
[ChangedAtUtc] [datetime2] (0) NOT NULL CONSTRAINT [DF_CustomerLoyaltyLog_ChangedAtUtc] DEFAULT (sysutcdatetime())
)
GO
ALTER TABLE [dbo].[CustomerLoyaltyLog] ADD CONSTRAINT [PK_CustomerLoyaltyLog] PRIMARY KEY CLUSTERED ([LoyaltyLogID])
GO
CREATE NONCLUSTERED INDEX [IX_CustomerLoyaltyLog_CustomerID] ON [dbo].[CustomerLoyaltyLog] ([CustomerID])
GO
ALTER TABLE [dbo].[CustomerLoyaltyLog] ADD CONSTRAINT [FK_CustomerLoyaltyLog_Customers] FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customers] ([CustomerID])
GO
