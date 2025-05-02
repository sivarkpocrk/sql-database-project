CREATE PROCEDURE dbo.spInsertUsers
    @NewUsers dbo.UserInputType READONLY
AS
BEGIN
    INSERT INTO dbo.Users (Username, Email, CreatedAt)
    SELECT Username, Email, CreatedAt FROM @NewUsers;
END
GO
