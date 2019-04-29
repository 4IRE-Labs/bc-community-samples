IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetLatLon')
DROP PROCEDURE GetLatLon
GO
CREATE  PROCEDURE GetLatLon
AS BEGIN
SET NOCOUNT ON

IF OBJECT_ID('tempdb..#WFL_TMP') IS NOT NULL
    begin
            drop table #WFL_TMP
    end

DECLARE @WFL_ID_1 INT
DECLARE @WFL_ID_2 INT
DECLARE @WFL_ID_3 INT

;WITH tmp AS 
    ( select TOP 1 app.Id, wfl.ID AS WFLID, wst.VALUE
    from dbo.Application as app
        LEFT JOIN dbo.workflow as wfl
            ON app.ID = wfl.ApplicationId
        LEFT JOIN dbo.WorkflowState wst
            ON wfl.ID = wst.WORKFLOWID
    where  app.Name = 'BigDayUmbrella' AND wst.VALUE = 1
    order by app.VERSION DESC
    )
    SELECT * INTO #WFL_TMP from tmp

    select @WFL_ID_1 = wpr.id from dbo.Workflowproperty wpr where wpr.Name = 'STATE' and wpr.WORKFLOWID = (SELECT TOP 1 WFLID From #WFL_TMP)
    select @WFL_ID_2 = wpr.id from dbo.Workflowproperty wpr where wpr.Name = 'Lat' and wpr.WORKFLOWID = (SELECT TOP 1 WFLID From #WFL_TMP)
    select @WFL_ID_3 = wpr.id from dbo.Workflowproperty wpr where wpr.Name = 'Lon' and wpr.WORKFLOWID = (SELECT TOP 1 WFLID From #WFL_TMP)
    

        SELECT 
         tar1.ContractId,
         tar1.LAT, 
         tar3.LON,
         con.LEDGERIDENTIFIER
    FROM 
   (SELECT 
        cpr2.ContractID, 
        LAT = cpr2.VALUE,
        rnum = ROW_NUMBER() OVER (PARTITION BY cpr2.ContractID ORDER BY cpr2.ID DESC)
    FROM dbo.Contractproperty cpr2
    WHERE cpr2.ContractID IN
        (
        select cpr.ContractID from dbo.Contractproperty cpr
            where cpr.WORKFLOWPROPERTYID = @WFL_ID_1
            AND cpr.VALUE = 1
        ) AND cpr2.WORKFLOWPROPERTYID = @WFL_ID_2
    ) tar1 
LEFT JOIN
(
   SELECT 
         tar2.ContractId,
         tar2.LON
    FROM 
   (SELECT 
        cpr2.ContractID, 
        LON = cpr2.VALUE,
        rnum = ROW_NUMBER() OVER (PARTITION BY cpr2.ContractID ORDER BY cpr2.ID DESC)
    FROM dbo.Contractproperty cpr2
    WHERE cpr2.ContractID IN
        (
        select cpr.ContractID from dbo.Contractproperty cpr
            where cpr.WORKFLOWPROPERTYID = @WFL_ID_1
            AND cpr.VALUE = 1
        ) AND cpr2.WORKFLOWPROPERTYID = @WFL_ID_3
    ) tar2 WHERE tar2.rnum = 1
)  tar3  
ON tar1.ContractID = tar3.ContractID
LEFT JOIN dbo.Contract con
ON tar1.ContractID = con.ID
WHERE tar1.rnum = 1

END

EXEC dbo.GetLatLon; 