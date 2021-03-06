USE [TD5R1]
GO
/****** Object:  UserDefinedFunction [dbo].[GetOrdTarifNameByTId]    Script Date: 09/15/2014 13:13:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER FUNCTION [dbo].[GetOrdTarifNameByTId]  ( @tid int)
RETURNS varchar(255)
AS
BEGIN
	declare @res varchar(255)
   
	SET @res='Не указан';
   
	SELECT @res=TARIF_NAME   
	FROM ORDER_TARIF WHERE 
    ID=@tid;
    
    SET @res=ISNULL(@res,'Не указан'); 

	RETURN(@res)
END
