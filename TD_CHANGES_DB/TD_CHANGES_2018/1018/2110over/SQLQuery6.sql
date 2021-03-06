USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[AssignDriverOnOrder]    Script Date: 26.10.2018 5:37:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






ALTER PROCEDURE [dbo].[AssignDriverByNumOnOrder] 
	-- Add the parameters for the stored procedure here
	(@order_id int, @driver_num int, @user_id int, @count int OUT)
AS
BEGIN 
	DECLARE @driver_id int;
	
	SET @count = 0;

	SELECT TOP 1 @driver_id = BOLD_ID
	FROM Voditelj
	WHERE Pozyvnoi = @driver_num;

	IF @@ROWCOUNT > 0 BEGIN
		EXEC dbo.AssignDriverOnOrder @order_id, @driver_id, 
			@user_id, @count = @count OUT;
	END;
	
END










