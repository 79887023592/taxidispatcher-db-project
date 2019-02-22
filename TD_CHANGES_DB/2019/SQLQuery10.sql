USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_DRIVER_ASSIGN]    Script Date: 20.02.2019 1:53:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER TRIGGER [dbo].[AFTER_DRIVER_ASSIGN] 
   ON  [dbo].[Zakaz] 
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @db_version INT,
		@clsms_offlinedr_assign smallint,
		@use_drivers_rating smallint,
		@rating_bonus decimal(18, 5);
	
	SELECT TOP 1 @db_version=ISNULL(db_version,3),
	@clsms_offlinedr_assign = clsms_offlinedr_assign,
	@use_drivers_rating = use_drivers_rating
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	IF((@db_version>=5))
	BEGIN

	DECLARE @nOldValue int, @newDrId int, @oldDrId int, @ofl_cnt int;
		
	SELECT @nOldValue=b.BOLD_ID, 
	@newDrId=a.vypolnyaetsya_voditelem,
	@oldDrId=b.vypolnyaetsya_voditelem
	FROM inserted a, deleted b;
	
	IF((@newDrId<>@oldDrId) and (@newDrId>0))
	BEGIN

		IF @use_drivers_rating = 1 BEGIN
			EXEC GetOrderRatingBonus @nOldValue, 0, 0, 0, 
				@rating_bonus = @rating_bonus OUTPUT; 
		END;
	
		UPDATE Zakaz SET dr_assign_date=GETDATE() WHERE BOLD_ID=@nOldValue;
		
		SELECT @ofl_cnt = COUNT(*) FROM Voditelj v WHERE v.BOLD_ID=@newDrId AND v.ITS_REMOTE_CLIENT<>1
		IF (@ofl_cnt>0) AND (@clsms_offlinedr_assign=1) BEGIN
			UPDATE Zakaz SET CLIENT_SMS_SEND_STATE=1
			WHERE BOLD_ID=@nOldValue;
		END;
	END;

	END;
	
	
	
END


