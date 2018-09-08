USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_ORDER_SYNC]    Script Date: 24.09.2017 20:02:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TRIGGER [dbo].[AFTER_ORDER_SYNC] 
   ON  [dbo].[Zakaz] 
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @db_version INT, @sync_account int, 
	@clsms_ordground smallint,
	@use_fordbroadcast_priority smallint;
	
	SELECT TOP 1 @db_version=ISNULL(db_version,3),
	@sync_account=ISNULL(sync_busy_accounting,0),
	@clsms_ordground=ISNULL(clsms_ordground,0),
	@use_fordbroadcast_priority=use_fordbroadcast_priority 
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	IF((@db_version>=5) AND (@sync_account>0))
	BEGIN

	DECLARE @nOldValue int, @nNewValue int, 
		@RSOldValue INT, @NewSyncValue INT,
		@OldSyncValue int, @newDrId int;
		
		
	SELECT @nOldValue=b.BOLD_ID, 
	@nNewValue=a.REMOTE_SET,
	@RSOldValue=b.REMOTE_SET,
	@OldSyncValue=b.REMOTE_SYNC,
	@NewSyncValue=a.REMOTE_SYNC,
	@newDrId=a.vypolnyaetsya_voditelem
	FROM inserted a, deleted b

	IF ((@NewSyncValue=0) AND (@NewSyncValue<>@OldSyncValue) 
		AND (@newDrId>0))
	BEGIN
		EXEC CheckDriverBusy @newDrId;
		EXEC SetDriverStatSyncStatus @newDrId, 1, 0;
	END;
	
	IF ((@NewSyncValue=0) AND (@NewSyncValue<>@OldSyncValue) 
		AND (@newDrId>0) AND (@clsms_ordground=1))
	BEGIN
		UPDATE Zakaz SET CLIENT_SMS_SEND_STATE=1
		WHERE BOLD_ID=@nOldValue;
	END;

	IF (@use_fordbroadcast_priority = 1) AND (@NewSyncValue<>@OldSyncValue)
	BEGIN
		EXEC RefreshDrOrdPriorityBroadcasts;
	END;

	END;
	
	
	
END
