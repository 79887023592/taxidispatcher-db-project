USE [TD5R1]
GO
/****** Object:  StoredProcedure [dbo].[ProceedOperationRequest]    Script Date: 12/26/2013 01:33:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[ProceedOperationRequest] 
	-- Add the parameters for the stored procedure here
	(@opnm varchar(255), @prm1 varchar(255), @prm2 varchar(255), 
	 @prm3 varchar(255), @prm4 varchar(255), @prm5 varchar(255), 
	 @op_answer varchar(5000) OUT)
AS
BEGIN 

	SET @op_answer = '{"command":"opa","scs":"yes","opnm":"'+
		@opnm+'",';
	
	SET @op_answer = @op_answer + '"msg_end":"ok"}';
	
END



