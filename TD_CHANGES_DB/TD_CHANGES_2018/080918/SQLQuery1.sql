USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_DRIVER_UPDATE]    Script Date: 11.09.2018 14:29:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[AFTER_DRIVER_COORD_UPDATE] 
   ON  [dbo].[Voditelj] 
   AFTER UPDATE
AS 
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @db_version INT;
	
	SELECT TOP 1 @db_version=ISNULL(db_version,3) 
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	if(@db_version>=5)
	BEGIN
	
		DECLARE @nOldValue int, @newLat varchar(50),
			@newLon varchar(50), @oldLat varchar(50),
			@oldLon varchar(50);

		SELECT @nOldValue=b.BOLD_ID, 
		@newLat=a.last_lat,
		@newLon=a.last_lon,
		@oldLat=b.last_lat,
		@oldLon=b.last_lon
		FROM inserted a, deleted b;
	
		IF ((@newLat <> @oldLat AND NOT ISNULL(@newLat, '') <> '') OR 
			(@newLon <> @oldLon  AND NOT ISNULL(@newLon, '') <> '') )
		BEGIN
			UPDATE Voditelj 
			SET cc_monitoring_upd = 1
			WHERE BOLD_ID=@nOldValue;
		END;

	END;

END

