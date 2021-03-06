USE [TD5R1]
GO
/****** Object:  Trigger [dbo].[AFTER_ORDER_FIXTIMESET]    Script Date: 07/05/2014 04:39:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER TRIGGER [dbo].[AFTER_ORDER_FIXTIMESET] 
   ON  [dbo].[Zakaz] 
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @db_version INT, 
	@recalc_on_timeset smallint,
	@ftime_tariff decimal(28,10);
	
	SET @recalc_on_timeset=0;
	
	SELECT TOP 1 @db_version=ISNULL(db_version,3),
	@recalc_on_timeset=ISNULL(recalc_on_timeset,0),
	@ftime_tariff=ISNULL(ftime_tariff,0) 
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';
	
	IF((@db_version>=5) AND (@recalc_on_timeset=1))
	BEGIN
	
		DECLARE @oldfixed_time int, @newfixed_time int, 
			@newOrderId INT;
			
		SELECT @oldfixed_time=b.fixed_time, 
		@newfixed_time=a.fixed_time,
		@newOrderId=a.BOLD_ID
		FROM inserted a, deleted b

		IF ((@oldfixed_time<>@newfixed_time) AND (@ftime_tariff>0) AND (@newfixed_time>0))
		BEGIN
			UPDATE Zakaz SET fixed_summ=@newfixed_time*@ftime_tariff, 
				Uslovn_stoim=@newfixed_time*@ftime_tariff 
			WHERE BOLD_ID=@newOrderId;
		END;

	END;
	
	
	
END



