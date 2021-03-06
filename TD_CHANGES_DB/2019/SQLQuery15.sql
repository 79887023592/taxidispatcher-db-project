USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[AutoAssignDriverByCoords]    Script Date: 03.03.2019 11:37:59 ******/
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
	@aass_driver_max_radius int, @driver_id int,
	@autoasg_drby_coord_by_rating smallint;

	SELECT @aass_driver_max_radius = aass_driver_max_radius,
	@autoasg_drby_coord_by_rating = autoasg_drby_coord_by_rating
	FROM Objekt_vyborki_otchyotnosti
	WHERE Tip_objekta='for_drivers';

	SET @autoasg_drby_coord_by_rating = ISNULL(@autoasg_drby_coord_by_rating, 0);

	IF @latStr <> '' AND @lonStr <> '' BEGIN

		SET @lat = CAST(@latStr as decimal(28, 10));
		SET @lon = CAST(@lonStr as decimal(28, 10));

		IF @lat > -250 AND @lat < 250 AND @lon > -250 AND @lon < 250 BEGIN

			IF @autoasg_drby_coord_by_rating = 1 BEGIN
				SELECT TOP 1 @latDr = CAST(last_lat as decimal(28, 10)), 
				@lonDr = CAST(last_lon as decimal(28, 10)), @driver_id = BOLD_ID FROM Voditelj
				WHERE last_lat <> '' AND last_lon <> '' AND (ABS(DATEDIFF(minute, last_cctime, GETDATE())) < 10) 
				AND Zanyat_drugim_disp = 0 AND V_rabote = 1 AND Na_pereryve = 0 AND dont_auto_asgn_by_radius <> 1 AND 
				dbo.DistanceBetweenTwoCoords(@lat, @lon, CAST(last_lat as decimal(28, 10)), 
				CAST(last_lon as decimal(28, 10))) < (@aass_driver_max_radius/1000)
				ORDER BY dbo.GetDriverRating(BOLD_ID) DESC;
			END
			ELSE BEGIN
				SELECT TOP 1 @latDr = CAST(last_lat as decimal(28, 10)), 
				@lonDr = CAST(last_lon as decimal(28, 10)), @driver_id = BOLD_ID FROM Voditelj
				WHERE last_lat <> '' AND last_lon <> '' AND (ABS(DATEDIFF(minute, last_cctime, GETDATE())) < 10) 
				AND Zanyat_drugim_disp = 0 AND V_rabote = 1 AND Na_pereryve = 0 AND dont_auto_asgn_by_radius <> 1
				ORDER BY dbo.DistanceBetweenTwoCoords(@lat, @lon, CAST(last_lat as decimal(28, 10)), 
				CAST(last_lon as decimal(28, 10))) ASC;
			END;

			IF @@ROWCOUNT > 0 AND @latDr > -250 AND @latDr < 250 AND 
				@lonDr > -250 AND @lonDr < 250
			BEGIN
				IF @autoasg_drby_coord_by_rating = 1 BEGIN
					EXEC AssignDriverOnOrder @order_id, @driver_id, 
						-1, @count = @count OUTPUT;
				END
				ELSE IF (dbo.DistanceBetweenTwoCoords(@lat, @lon, @latDr, @lonDr) * 1000) < 
				(@aass_driver_max_radius/1000) BEGIN
					EXEC AssignDriverOnOrder @order_id, @driver_id, 
						-1, @count = @count OUTPUT;
				END;
			END;

		END;

	END;

END










