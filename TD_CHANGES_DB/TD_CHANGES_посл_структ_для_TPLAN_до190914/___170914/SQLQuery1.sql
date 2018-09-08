USE [TD5R1]
GO

/****** Object:  Table [dbo].[PRICE_POLICY]    Script Date: 09/17/2014 22:03:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[PRICE_POLICY](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[POLICY_NAME] [varchar](255) NOT NULL,
 CONSTRAINT [PK_PRICE_POLICY] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[PRICE_POLICY] ADD  CONSTRAINT [DF_PRICE_POLICY_POLICY_NAME]  DEFAULT ('������� �������� �') FOR [POLICY_NAME]
GO


