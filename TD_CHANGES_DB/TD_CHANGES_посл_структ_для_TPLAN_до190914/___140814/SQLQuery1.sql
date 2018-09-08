USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[IncrementOrdersPriority]    Script Date: 08/14/2014 22:20:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ResetRemoteDriversFlags] 
	-- Add the parameters for the stored procedure here
AS
BEGIN 

	UPDATE Voditelj SET WAS_REMOTE_CLIENT=ITS_REMOTE_CLIENT;
	UPDATE Voditelj SET ITS_REMOTE_CLIENT=0;

END
