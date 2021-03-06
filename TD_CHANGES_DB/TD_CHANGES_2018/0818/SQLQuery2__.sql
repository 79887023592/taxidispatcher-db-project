USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[OneMinuteTask]    Script Date: 24.08.2018 20:51:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[OneMinuteTask] 
	(@success int OUT)
AS
BEGIN

	SET @success=0;

	BEGIN TRY
		SET @success=1;
		UPDATE Voditelj 
		SET DR_SUMM=dbo.GetDrWorkSumm(BOLD_ID);

		EXEC CheckDriversRatingExpires;
	END TRY
	BEGIN CATCH
		SET @success=0;
	END CATCH;

END

