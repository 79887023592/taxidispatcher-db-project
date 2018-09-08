USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[SetOrderDriverCancelAttStatus]    Script Date: 05/13/2014 00:13:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SetOrderDriverCancelAttStatus] 
	-- Add the parameters for the stored procedure here
	(@order_id int, @dr_id int, @count int OUT)
AS
BEGIN 
	--DECLARE @count int;
	SET @count = 0;
	
	UPDATE Zakaz 
	SET Zakaz.REMOTE_SET=13 
	WHERE (Zakaz.REMOTE_SET=8) AND  
	(Zakaz.BOLD_ID=@order_id) AND
	(Zakaz.vypolnyaetsya_voditelem=@dr_id);
	
	SET @count=@@ROWCOUNT;
	
END







