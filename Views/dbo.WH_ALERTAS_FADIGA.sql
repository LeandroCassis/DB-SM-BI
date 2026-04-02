SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[WH_ALERTAS_FADIGA] 
AS SELECT
UPPER(Empresa.Descricao) 'EMPRESA', 
AlertaFadiga.Id 'ID ALERTA',
AlertaFadiga.IdEquipamento 'ID EQUIPAMENTO',
UPPER(Equipamento.Descricao) 'EQUIPAMENTO',
AlertaFadiga.IdOperador 'ID OPERADOR',
UPPER(_OP.Nome) 'OPERADOR',
AlertaFadiga.IdTurno 'ID TURNO',
UPPER(Turno.Descricao) 'TURNO', 
AlertaFadiga.TipoAlerta 'COD TIPO ALERTA',
UPPER(TipoAlertaFadiga.Descricao) 'TIPO ALERTA',
CAST(AlertaFadiga.Data AS DATE) 'DATA ALERTA',
AlertaFadiga.Data 'DATA HORA ALERTA',
AlertaFadiga.Velocidade 'VELOCIDADE',
AlertaFadiga.DataSync 'DATA INTEGRAÇÃO',
AlertaFadiga.Situacao 'COD SITUAÇÃO',
CASE AlertaFadiga.Situacao
        WHEN 'P' THEN 'PENDENTE'
        WHEN 'V' THEN 'VÁLIDA'
        ELSE 'INVÁLIDA'
        END 'SITUAÇÃO',
AlertaFadiga.IdEquipamento 'ID USUÁRIO AVALIAÇÃO',
UPPER(_UA.Nome) 'USUÁRIO AVALIAÇÃO',
IIF(TipoAlertaFadiga.Risco='A', 'ALTO',
IIF(TipoAlertaFadiga.Risco='M', 'MÉDIO',
IIF(TipoAlertaFadiga.Risco='B', 'BAIXO','VERIFICAR'))) 'RISCO',
AlertaFadiga.ClassificacaoAlerta 'COD CLASSIFICAÇÃO',
IIF(AlertaFadiga.ClassificacaoAlerta='I', 'ISOLADO',
IIF(AlertaFadiga.ClassificacaoAlerta='R', 'REINCIDENTE',
IIF(AlertaFadiga.ClassificacaoAlerta='C', 'CRÍTICO','NÃO CLASSIFICADO'))) 'CLASSIFICAÇÃO'

FROM RajaMine.dbo.AlertaFadiga WITH (NOLOCK)
LEFT JOIN RajaMine.dbo.TipoAlertaFadiga  WITH (NOLOCK)
ON AlertaFadiga.IdTipoAlertaFadiga = TipoAlertaFadiga.Id

LEFT JOIN RajaMine.dbo.Equipamento  WITH (NOLOCK)
ON AlertaFadiga.IdEquipamento = Equipamento.Id

LEFT JOIN RajaMine.dbo.Usuario _UA  WITH (NOLOCK)
ON AlertaFadiga.IdUsuarioAvaliacao = _UA.Id

LEFT JOIN RajaMine.dbo.Operador _OP WITH (NOLOCK)
ON AlertaFadiga.IdOperador = _OP.Id

LEFT JOIN RajaMine.dbo.Empresa WITH (NOLOCK)                   
ON Equipamento.IdEmpresa = Empresa.Id

LEFT JOIN RajaMine.dbo.Turno WITH (NOLOCK)                     
ON Turno.Id = AlertaFadiga.IdTurno


WHERE AlertaFadiga.Data >= '2025-01-01' 




--SELECT 
--    UPPER(Empresa.Descricao) 'EMPRESA',                            -- Nome da empresa
--    UPPER(Operador.Nome) 'OPERADOR',                               -- Nome do operador
--    UPPER(Equipamento.Descricao) 'EQUIPAMENTO',                    -- Nome do equipamento
--    FORMAT(AlertaFadiga.Data, 'dd/MM/yyyy') 'DATA',                        -- Data do alerta
--    FORMAT(AlertaFadiga.Data, 'HH:mm') 'HORA',                     -- Hora do alerta
--    UPPER(Turno.Descricao) 'TURNO',                                -- Descrição do turno
--    TipoAlertaFadiga.Codigo 'COD ALERTA',                          -- Código do tipo de alerta
--    UPPER(TipoAlertaFadiga.Descricao) 'TIPO ALERTA',              -- Tipo de alerta de fadiga
--    AlertaFadiga.Velocidade '#VELOCIDADE',                         -- Velocidade registrada
--    CASE AlertaFadiga.Situacao
--        WHEN 'P' THEN 'PENDENTE'
--        WHEN 'V' THEN 'VÁLIDA'
--        ELSE 'INVÁLIDA'
--    END 'SITUAÇÃO'                                                 -- Status do alerta
--FROM RajaMine.dbo.AlertaFadiga WITH (NOLOCK)                      -- Tabela principal de alertas
--INNER JOIN RajaMine.dbo.TipoAlertaFadiga WITH (NOLOCK)            -- Tipos de alerta
--    ON TipoAlertaFadiga.Codigo = AlertaFadiga.TipoAlerta
--LEFT JOIN RajaMine.dbo.Turno WITH (NOLOCK)                        -- Turnos de trabalho
--    ON Turno.Id = AlertaFadiga.IdTurno
--LEFT JOIN RajaMine.dbo.Equipamento WITH (NOLOCK)                  -- Equipamentos monitorados
--    ON Equipamento.Id = AlertaFadiga.IdEquipamento
--LEFT JOIN RajaMine.dbo.Operador WITH (NOLOCK)                     -- Operadores dos equipamentos
--    ON Operador.Id = AlertaFadiga.IdOperador
--LEFT JOIN RajaMine.dbo.Empresa WITH (NOLOCK)                      -- Empresas do grupo
--    ON Equipamento.IdEmpresa = Empresa.Id
--WHERE AlertaFadiga.Data >= '2025-01-01'           -- Últimos 30 dias

GO