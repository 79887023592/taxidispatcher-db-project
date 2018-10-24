USE [TD5R1]
GO

/****** Object:  UserDefinedFunction [dbo].[DegToRad]    Script Date: 20.10.2018 22:27:05 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[DegToRad]  ( @deg decimal(18,5))
RETURNS decimal(18,5)
AS
BEGIN 
   RETURN (@deg * PI() / 180)
END
GO


