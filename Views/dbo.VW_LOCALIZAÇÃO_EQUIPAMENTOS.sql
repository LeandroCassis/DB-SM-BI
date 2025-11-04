SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE   VIEW [dbo].[VW_LOCALIZAÇÃO_EQUIPAMENTOS] AS

SELECT 

*


FROM (

SELECT

[ID EQUIPAMENTO],
[DATA INÍCIO VIAGEM]
[ID VIAGEM],
LATITUDE,
LONGITUDE,
ROW_NUMBER() OVER (PARTITION BY [ID EQUIPAMENTO] ORDER BY [DATA INÍCIO VIAGEM] DESC) 'RN'


FROM (
SELECT
InicioViagem 'DATA INÍCIO VIAGEM'
,IdEquipamentoTransporte 'ID EQUIPAMENTO'
,REPLACE(IIF(LatitudeInicioViagem=0,NULL,LatitudeInicioViagem),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeInicioViagem=0,NULL,LongitudeInicioViagem),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024


UNION ALL

SELECT
InicioViagem 'DATA INÍCIO VIAGEM'
,IdEquipamentoTransporte 'ID EQUIPAMENTO'
,REPLACE(IIF(LatitudeInicioCarga=0,NULL,LatitudeInicioCarga),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeInicioCarga=0,NULL,LongitudeInicioCarga),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024
UNION ALL

SELECT
InicioViagem 'DATA INÍCIO VIAGEM'
,IdEquipamentoTransporte 'ID EQUIPAMENTO'
,REPLACE(IIF(LatitudeFimCarga=0,NULL,LatitudeFimCarga),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeFimCarga=0,NULL,LongitudeFimCarga),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024
UNION ALL

SELECT
InicioViagem 'DATA INÍCIO VIAGEM'
,IdEquipamentoTransporte 'ID EQUIPAMENTO'
,REPLACE(IIF(LatitudeInicioBascula=0,NULL,LatitudeInicioBascula),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeInicioBascula=0,NULL,LongitudeInicioBascula),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024
UNION ALL

SELECT
InicioViagem 'DATA INÍCIO VIAGEM'
,IdEquipamentoTransporte 'ID EQUIPAMENTO'
,REPLACE(IIF(LatitudeFimBascula=0,NULL,LatitudeFimBascula),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeFimBascula=0,NULL,LongitudeFimBascula),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024

UNION ALL

SELECT
InicioViagem 'DATA INÍCIO VIAGEM'
,IdEquipamentoTransporte 'ID EQUIPAMENTO'
,REPLACE(IIF(LatitudeEquipamentoCarga=0,NULL,LatitudeEquipamentoCarga),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeEquipamentoCarga=0,NULL,LongitudeEquipamentoCarga),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024

) _DADOS


WHERE _DADOS.LATITUDE IS NOT NULL
AND _DADOS.LONGITUDE IS NOT NULL

) _DADOS_2


WHERE _DADOS_2.RN = 1
GO