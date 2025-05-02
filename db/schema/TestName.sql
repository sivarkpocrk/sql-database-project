CREATE TABLE [dbo].[TestName] (
    [Id]   INT            NOT NULL,
    [Name] NVARCHAR (100) NULL, -- Removed COLLATE clause
    PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
