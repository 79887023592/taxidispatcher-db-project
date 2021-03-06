USE [TD5R1]
GO
/****** Object:  UserDefinedFunction [dbo].[GetDrIDByNum]    Script Date: 19.10.2018 20:22:27 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER FUNCTION [dbo].[DistanceBetweenTwoCoords]  (@lat1 decimal(28,10), 
@lon1 decimal(28,10), @lat2 decimal(28,10), @lon2 decimal(28,10))
RETURNS decimal(28,10)
AS
BEGIN 
	DECLARE @earthRadius decimal(28,10), @dLat decimal(28,10), 
		@dLon decimal(28,10), @a decimal(28,10), @c decimal(28,10);

	SET @earthRadius = 6371;
	SET @dLat = dbo.DegToRad(@lat2 - @lat1);
	SET @dLon = dbo.DegToRad(@lon2 - @lon1);

	SET @lat1 = dbo.DegToRad(@lat1);
	SET @lat2 = dbo.DegToRad(@lat2);

	SET @a = SIN(@dLat/2) * SIN(@dLat/2) +
          SIN(@dLon/2) * SIN(@dLon/2) * COS(@lat1) * COS(@lat2); 
	SET @c = 2 * ATN2(SQRT(@a), SQRT(1-@a));

	RETURN (@earthRadius * @c)
END