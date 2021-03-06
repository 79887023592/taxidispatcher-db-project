USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_ONPLACE_TOBE]    Script Date: 23.02.2017 9:42:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER [dbo].[AFTER_ONPLACE_TOBE] 
   ON  [dbo].[Zakaz] 
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @db_version INT, 
	@clsms_onplaceto smallint;
	
	SELECT TOP 1 @db_version=ISNULL(db_version,3),
	@clsms_onplaceto=ISNULL(clsms_onplaceto,0) 
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	IF((@db_version>=5) AND (@clsms_onplaceto>0))
	BEGIN

	DECLARE @nOldValue smallint, @nNewValue smallint, 
		@RSNewValue INT, @newDrId int, @newOrderId int;
		
		
	SELECT @newOrderId=b.BOLD_ID, 
	@RSNewValue=a.REMOTE_SET,
	@nOldValue=b.on_place,
	@nNewValue=a.on_place,
	@newDrId=a.vypolnyaetsya_voditelem
	FROM inserted a, deleted b
	
	IF ((@nNewValue=1) AND (@nNewValue<>@nOldValue) 
		AND (@newDrId>0) AND (@clsms_onplaceto=1))
	BEGIN
		UPDATE Zakaz SET CLIENT_SMS_SEND_STATE=4
		WHERE BOLD_ID=@newOrderId;
	END;

	END;
	
	
	
END

