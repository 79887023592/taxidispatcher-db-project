USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[CheckDriversRatingExpires]    Script Date: 24.08.2018 20:50:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[CheckDriversRatingExpires] 
	-- Add the parameters for the stored procedure here
AS
BEGIN 
	DECLARE @use_drivers_rating smallint;

	SELECT TOP 1 @use_drivers_rating = use_drivers_rating
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';

	SET @use_drivers_rating = ISNULL(@use_drivers_rating,0);

	IF @use_drivers_rating > 0 BEGIN
		DELETE FROM DRIVER_RATING WHERE expire_date <= GETDATE();
	END;
END


