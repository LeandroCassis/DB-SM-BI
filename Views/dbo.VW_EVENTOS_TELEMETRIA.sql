SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_EVENTOS_TELEMETRIA] 
AS SELECT 
Telemetria.IdEquipamento 'ID EQUIPAMENTO',
CAST(Telemetria.DataRef AS DATE) 'DATA',
Telemetria.IdTelemetriaEvento 'ID EVENTO',
UPPER(TelemetriaEvento.Descricao) 'EVENTO',
SUM(Telemetria.Segundos)/3600.0 'HORAS'

FROM RajaMine.dbo.Telemetria

LEFT JOIN RajaMine.dbo.TelemetriaEvento WITH (NOLOCK)
ON Telemetria.IdTelemetriaEvento = TelemetriaEvento.Id


--LEFT JOIN VW_EQUIPAMENTOS
--ON Telemetria.IdEquipamento = VW_EQUIPAMENTOS.[ID EQUIPAMENTO RJM]


WHERE YEAR(DataRef) >=2024
--AND VW_EQUIPAMENTOS.CONTROLA = 'SIM'


GROUP BY 
Telemetria.Id,
Telemetria.IdEquipamento,
CAST(Telemetria.DataRef AS DATE),
Telemetria.IdTelemetriaEvento,
UPPER(TelemetriaEvento.Descricao) 
GO