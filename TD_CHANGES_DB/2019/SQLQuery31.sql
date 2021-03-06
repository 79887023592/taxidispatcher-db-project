USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_ORDER_DISTRICT_OR_SECTOR_SET]    Script Date: 22.04.2019 1:50:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER [dbo].[AFTER_ORDER_DISTRICT_OR_SECTOR_SET] 
   ON  [dbo].[Zakaz] 
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @db_version INT, @use_priority int;
	
	SELECT TOP 1 @db_version=ISNULL(db_version,3),
	@use_priority=ISNULL(use_dr_priority,0) 
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	IF((@db_version>=5) AND (@use_priority>0))
	BEGIN

	DECLARE @idValue int, @newDSIDValue int, 
		@oldDSIDValue INT, @newDIDlValue INT,
		@oldDIDValue int, @companyId int;
			
	SELECT @idValue=b.BOLD_ID, 
	@newDSIDValue=a.detected_sector,
	@oldDSIDValue=b.detected_sector,
	@newDIDlValue=a.district_id,
	@oldDIDValue=b.district_id,
	@companyId = b.company_id
	FROM inserted a, deleted b

	IF @companyId < 0 BEGIN
		IF (@newDIDlValue > 0 AND @newDIDlValue <> @oldDIDValue)
		BEGIN
			SELECT TOP 1 @companyId = ds.company_id FROM DISTRICTS ds 
			WHERE ds.id = @newDIDlValue;
			UPDATE Zakaz SET company_id = @companyId WHERE BOLD_ID = @idValue;
		END
		ELSE IF (@newDSIDValue > 0 AND @newDSIDValue <> @oldDSIDValue)
		BEGIN
			SELECT TOP 1 @companyId = ws.company_id FROM Sektor_raboty ws 
			WHERE ws.BOLD_ID = @newDSIDValue;
			UPDATE Zakaz SET company_id = @companyId WHERE BOLD_ID = @idValue;
		END;
	END;

	END;
	
END


