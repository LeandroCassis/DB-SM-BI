SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_GEOLOCALIZAÇÃO] 
AS SELECT 

[ID VIAGEM],
[TIPO LOCAL],
LATITUDE,
LONGITUDE


FROM (
SELECT
  Id 'ID VIAGEM'
,'ÍNÍCIO VIAGEM' AS 'TIPO LOCAL'
,REPLACE(IIF(LatitudeInicioViagem=0,NULL,LatitudeInicioViagem),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeInicioViagem=0,NULL,LongitudeInicioViagem),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024


UNION ALL

SELECT
  Id 'ID VIAGEM'
,'ÍNÍCIO CARGA' AS 'TIPO LOCAL'
,REPLACE(IIF(LatitudeInicioCarga=0,NULL,LatitudeInicioCarga),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeInicioCarga=0,NULL,LongitudeInicioCarga),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024
UNION ALL

SELECT
  Id 'ID VIAGEM'
,'FIM CARGA' AS 'TIPO LOCAL'
,REPLACE(IIF(LatitudeFimCarga=0,NULL,LatitudeFimCarga),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeFimCarga=0,NULL,LongitudeFimCarga),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024
UNION ALL

SELECT
  Id 'ID VIAGEM'
,'INÍCIO BASCULA' AS 'TIPO LOCAL'
,REPLACE(IIF(LatitudeInicioBascula=0,NULL,LatitudeInicioBascula),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeInicioBascula=0,NULL,LongitudeInicioBascula),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024
UNION ALL

SELECT
  Id 'ID VIAGEM'
,'FIM BASCULA' AS 'TIPO LOCAL'
,REPLACE(IIF(LatitudeFimBascula=0,NULL,LatitudeFimBascula),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeFimBascula=0,NULL,LongitudeFimBascula),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024

UNION ALL

SELECT
  Id 'ID VIAGEM'
,'EQUIPAMENTO CARGA' AS 'TIPO LOCAL'
,REPLACE(IIF(LatitudeEquipamentoCarga=0,NULL,LatitudeEquipamentoCarga),',','.') 'LATITUDE'
,REPLACE(IIF(LongitudeEquipamentoCarga=0,NULL,LongitudeEquipamentoCarga),',','.') 'LONGITUDE'

FROM RajaMine.dbo.Viagem WITH (NOLOCK)
WHERE Ano >= 2024

) _DADOS


WHERE _DADOS.LATITUDE IS NOT NULL
AND _DADOS.LONGITUDE IS NOT NULL
GO