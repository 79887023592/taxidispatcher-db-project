USE [TD5R1]
GO
/****** Object:  UserDefinedFunction [dbo].[GetJSONTarifAndOptionsList]    Script Date: 04.05.2019 15:30:15 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER FUNCTION [dbo].[GetJSONTarifAndOptionsList] (@driver_id int)
RETURNS varchar(max)
AS
BEGIN
	declare @res varchar(max);
	DECLARE @company_id int;
   
	SET @res='{"command":"to_lst"';
	--SET @counter = 0;
	--SET @policy_id = -1;

	SELECT @company_id = gv.BOLD_ID --@policy_id = gv.PR_POLICY_ID, 
	FROM Voditelj dr INNER JOIN Gruppa_voditelei gv ON dr.otnositsya_k_gruppe = gv.BOLD_ID
	WHERE dr.BOLD_ID = @driver_id;

	IF @@ROWCOUNT = 1 BEGIN
		--SET @policy_id = -1;
		--SET @company_id = -1;

		SET @res = @res + dbo.GetJSONCompanyTOList(@company_id);
		--SELECT @policy_id = dr.PR_POLICY_ID
		--FROM Voditelj dr
		--WHERE dr.BOLD_ID = @driver_id;

		--IF @@ROWCOUNT <= 0 BEGIN
		--	SET @policy_id = -1;
		--END;
	END;
	------------------------------
	
	SET @res = @res + ',"msg_end":"ok"}';

	RETURN(@res)
END
