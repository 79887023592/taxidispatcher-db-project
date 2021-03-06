USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[AssignDriverOnOrder]    Script Date: 19.10.2018 20:49:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[AutoAssignDriverByCoords] 
	-- Add the parameters for the stored procedure here
	(@order_id int, @latStr varchar(50), @lonStr varchar(50), @count int OUT)
AS
BEGIN 
	DECLARE @prev_dr_id int, 
	@on_launch int, @driverNum int,
	@lat decimal(28,10), @lon decimal(28,10),
	@latDr decimal(28,10), @lonDr decimal(28,10),
	@aass_driver_max_radius int, @driver_id int;

	SELECT @aass_driver_max_radius = aass_driver_max_radius
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';

	IF @latStr <> '' AND @lonStr <> '' BEGIN

		SET @lat = CAST(@latStr as decimal(28, 10));
		SET @lon = CAST(@lonStr as decimal(28, 10));

		IF @lat > -250 AND @lat < 250 AND @lon > -250 AND @lon < 250 BEGIN

			SELECT TOP 1 @latDr = CAST(last_lat as decimal(28, 10)), 
			@lonDr = CAST(last_lon as decimal(28, 10)), @driver_id = BOLD_ID FROM Voditelj
			WHERE last_lat <> '' AND last_lon <> '' AND (ABS(DATEDIFF(minute, last_cctime, GETDATE())) < 10) 
			AND Zanyat_drugim_disp = 0 AND V_rabote = 1 AND Na_pereryve = 0 
			ORDER BY dbo.DistanceBetweenTwoCoords(@lat, @lon, CAST(last_lat as decimal(28, 10)), 
			CAST(last_lon as decimal(28, 10))) ASC;

			IF @@ROWCOUNT > 0 AND @latDr > -250 AND @latDr < 250 AND 
				@lonDr > -250 AND @lonDr < 250
			BEGIN
				IF (dbo.DistanceBetweenTwoCoords(@lat, @lon, @latDr, @lonDr) * 1000) < 
				@aass_driver_max_radius BEGIN
					EXEC AssignDriverOnOrder @order_id, @driver_id, 
						-1, @count = @count OUTPUT;
				END;
			END;

		END;

	END;

END










