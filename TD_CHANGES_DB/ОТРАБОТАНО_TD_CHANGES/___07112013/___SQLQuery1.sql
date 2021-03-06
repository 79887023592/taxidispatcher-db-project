ALTER PROCEDURE [dbo].[SetOrderCompleteAttemptStatus] 
	-- Add the parameters for the stored procedure here
	(@order_id int,  @driver_id int, @summ float, @count int OUT, @status int)
AS
BEGIN 
	--DECLARE @dr_num int;
	SET @count = 0;

	SELECT @count=COUNT(*) FROM Zakaz
	WHERE ((Zakaz.REMOTE_SET=8) OR 
	(Zakaz.REMOTE_SET=10)) AND 
	(Zakaz.BOLD_ID=@order_id) AND
	(Zakaz.vypolnyaetsya_voditelem=@driver_id);
	
	IF(@count>0)
	BEGIN
	
	UPDATE Zakaz 
	SET Zakaz.REMOTE_SET=@status,
	Zakaz.REMOTE_SUMM=@summ,
	Zakaz.Uslovn_stoim=@summ,
	Zakaz.CLIENT_SMS_SEND_STATE=3 
	WHERE  
	(Zakaz.BOLD_ID=@order_id);
	
	UPDATE Voditelj 
	SET Vremya_poslednei_zayavki=CURRENT_TIMESTAMP 
	WHERE BOLD_ID=@driver_id;
	
	SET @count=@@ROWCOUNT;
	
	--ORDER_DRV_COMPLETE = 15;
		--ORDER_COMLETE_ALLOW = 16;
		--ORDER_COMPLETE_ALLOW_USER_WAIT = 26;
		--ORDER_CLOSE_ASK_WAIT = 27;
	
	--IF (@count>0)
	--BEGIN
	--	UPDATE Zakaz SET Uslovn_stoim=@summ
	--	WHERE (Zakaz.BOLD_ID=@order_id) AND
	--	(@status in (15,16,26));
	--END;
	
	EXEC CheckDriverBusy @driver_id;
	
	END
	
END

