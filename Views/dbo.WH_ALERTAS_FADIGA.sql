SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[WH_ALERTAS_FADIGA] 
AS /*
=====================================================================
 CONSULTA: ALERTAS DE FADIGA POR EMPRESA, EQUIPAMENTO E OPERADOR
 FUNCIONALIDADE: Análise detalhada de alertas de fadiga com hierarquia organizacional
 DATA DE CRIAÇÃO: 10/09/2025
 ÚLTIMA ATUALIZAÇÃO: 10/09/2025
 DESENVOLVIDO POR: VESPERTTINE (vesperttine.com)
 SISTEMA: Sistema RajaMine - Monitoramento de Fadiga SM METAIS
=====================================================================
*/

SELECT 
    UPPER(Empresa.Descricao) 'EMPRESA',                            -- Nome da empresa
    UPPER(Operador.Nome) 'OPERADOR',                               -- Nome do operador
    UPPER(Equipamento.Descricao) 'EQUIPAMENTO',                    -- Nome do equipamento
    FORMAT(AlertaFadiga.Data, 'dd/MM/yyyy') 'DATA',                        -- Data do alerta
    FORMAT(AlertaFadiga.Data, 'HH:mm') 'HORA',                     -- Hora do alerta
    UPPER(Turno.Descricao) 'TURNO',                                -- Descrição do turno
    TipoAlertaFadiga.Codigo 'COD ALERTA',                          -- Código do tipo de alerta
    UPPER(TipoAlertaFadiga.Descricao) 'TIPO ALERTA',              -- Tipo de alerta de fadiga
    AlertaFadiga.Velocidade '#VELOCIDADE',                         -- Velocidade registrada
    CASE AlertaFadiga.Situacao
        WHEN 'P' THEN 'PENDENTE'
        WHEN 'V' THEN 'VÁLIDA'
        ELSE 'INVÁLIDA'
    END 'SITUAÇÃO'                                                 -- Status do alerta
FROM RajaMine.dbo.AlertaFadiga WITH (NOLOCK)                      -- Tabela principal de alertas
INNER JOIN RajaMine.dbo.TipoAlertaFadiga WITH (NOLOCK)            -- Tipos de alerta
    ON TipoAlertaFadiga.Codigo = AlertaFadiga.TipoAlerta
LEFT JOIN RajaMine.dbo.Turno WITH (NOLOCK)                        -- Turnos de trabalho
    ON Turno.Id = AlertaFadiga.IdTurno
LEFT JOIN RajaMine.dbo.Equipamento WITH (NOLOCK)                  -- Equipamentos monitorados
    ON Equipamento.Id = AlertaFadiga.IdEquipamento
LEFT JOIN RajaMine.dbo.Operador WITH (NOLOCK)                     -- Operadores dos equipamentos
    ON Operador.Id = AlertaFadiga.IdOperador
LEFT JOIN RajaMine.dbo.Empresa WITH (NOLOCK)                      -- Empresas do grupo
    ON Equipamento.IdEmpresa = Empresa.Id
WHERE AlertaFadiga.Data >= '2025-01-01'           -- Últimos 30 dias
--ORDER BY AlertaFadiga.Data DESC, Equipamento.Descricao           -- Ordenar por data e equipamento 
GO