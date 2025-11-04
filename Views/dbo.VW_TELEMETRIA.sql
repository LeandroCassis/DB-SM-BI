SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_TELEMETRIA] 
AS SELECT
kml.id_equipamento AS 'ID EQUIPAMENTO RJM'
--,kml.equipamento AS 'EQUIPAMENTO RJM'
,kml.DATA AS 'DATA'
,'TELEMETRIA' AS 'ORIGEM'
,IIF(kml.km_distancia=0,NULL,kml.km_distancia) AS '#KILOMETRAGEM'
,IIF(kml.l_combustivel=0,NULL,kml.l_combustivel) AS '#COMBUSTÍVEL'

,IIF((SELECT
      SUM(t.Segundos) / 3600.0
    FROM RajaMine.dbo.Telemetria t
    WHERE t.IdTelemetriaEvento = 123
    AND t.DataRef = kml.DATA
    AND t.IdEquipamento = kml.id_equipamento)=0,NULL,
 (SELECT
      SUM(t.Segundos) / 3600.0
    FROM RajaMine.dbo.Telemetria t
    WHERE t.IdTelemetriaEvento = 123
    AND t.DataRef = kml.DATA
    AND t.IdEquipamento = kml.id_equipamento)) AS  '#HORAS'

--,VW_EQUIPAMENTOS.CONTROLA
,'TELEMETRIA' AS 'TIPO ABASTECIMENTO'
FROM (SELECT -- equipamento
equipamento.Descricao AS equipamento,
equipamento.UnidadeHorimetroRastrador,

-- telemetria
telemetria.id_equipamento AS id_equipamento
,telemetria.Data
,(telemetria.maior_hodometro - telemetria.menor_hodometro) AS km_distancia
,(telemetria.maior_consumo - telemetria.menor_consumo) /
CASE
WHEN equipamento.unidade_consumo = 'L' THEN 1
ELSE 1000.0
END AS l_combustivel
FROM (SELECT
telemetria.IdEquipamento AS id_equipamento
,CAST(telemetria.Data AS DATE) 'DATA'
,MIN(COALESCE(telemetria.Odometro, 0.0)) / 1000.0 AS menor_hodometro
,MAX(COALESCE(telemetria.Odometro, 0.0)) / 1000.0 AS maior_hodometro
,MIN(COALESCE(telemetria.consumo, 0.0)) AS menor_consumo
,MAX(COALESCE(telemetria.consumo, 0.0)) AS maior_consumo



FROM RajaMine.dbo.TelemetriaOdometro telemetria WITH (NOLOCK)
WHERE YEAR(telemetria.Data) >=2024
GROUP BY telemetria.IdEquipamento
,CAST(telemetria.Data AS DATE)) telemetria
INNER JOIN (SELECT
equipamento.id AS id
,equipamento.id_tipo_equipamento AS id_tipo_equipamento
,equipamento.descricao AS descricao
,equipamento.unidade_consumo AS unidade_consumo
,equipamento.UnidadeHorimetroRastrador
FROM (SELECT
equipamento.descricao AS descricao
,equipamento.id AS id
,equipamento.IdTipoEquipamento AS id_tipo_equipamento
,equipamento.UnidadeConsumoRastrador AS unidade_consumo
,equipamento.UnidadeHorimetroRastrador
FROM RajaMine.dbo.equipamento WITH (NOLOCK)

) equipamento
INNER JOIN (SELECT
TipoEquipamento.id
,TipoEquipamento.descricao
FROM RajaMine.dbo.TipoEquipamento WITH (NOLOCK)
WHERE TipoEquipamento.Tipo IN (0, 2, 4)

) tipo_equipamento
ON tipo_equipamento.id = equipamento.id_tipo_equipamento) equipamento

ON equipamento.id = telemetria.id_equipamento) kml

WHERE (ABS(kml.km_distancia)+ABS(kml.l_combustivel))>0
--AND YEAR(kml.DATA) >= 2024



UNION ALL

SELECT
 AbastecimentoReal.IdEquipamento 'ID EQUIPAMENTO RAJAMINE'
,CAST(AbastecimentoReal.Inicio AS DATE) 'DATA'
,'ABASTECIMENTO' AS 'ORIGEM'
,IIF(AbastecimentoReal.DistanciaPercorrida= 0,NULL,AbastecimentoReal.DistanciaPercorrida)  '#KILOMETRAGEM'
,IIF(AbastecimentoReal.Litros = 0,NULL,AbastecimentoReal.Litros) '#COMBUSTÍVEL'
,AbastecimentoReal.Horimetro - LAG(AbastecimentoReal.Horimetro, 1, AbastecimentoReal.Horimetro) OVER (PARTITION BY AbastecimentoReal.IdEquipamento ORDER BY AbastecimentoReal.Inicio) '#HORAS'

,          CASE AbastecimentoReal.TipoAbastecimento
             WHEN 'A' THEN 'ABASTECIMENTO COMBOIO'
             WHEN 'B' THEN 'BOMBA'
             WHEN 'C' THEN 'COMBOIO'
             WHEN 'E' THEN 'EQUIPAMENTO'
             ELSE ''
          END AS 'TIPO ABASTECIMENTO'

FROM RajaMine.dbo.AbastecimentoReal WITH (NOLOCK)


WHERE  COALESCE(AbastecimentoReal.IdUsuario,0) <> 59
GO