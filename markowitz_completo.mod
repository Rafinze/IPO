# ================================================
# 1. CONJUNTOS E PARÂMETROS
# ================================================

# --- Conjuntos ---
set ATIVOS; # O universo de todas as P=55 ações
set SETORES; # Um conjunto com o nome de todos os setores relevantes

# --- Parâmetros ---
# Mapeia quais ativos pertencem a cada setor. Ex: Ativos_Por_Setor['Bancario']
set Ativos_Por_Setor {SETORES} within ATIVOS;

# Parâmetros escalares da estratégia
param m;
param W_max;
param R_target;

# Parâmetros de mercado
param mu {ATIVOS};
param Sigma {ATIVOS, ATIVOS};

# --- Novos Parâmetros para as Regras Lógicas ---
set SETORES_FINANCEIROS within SETORES;
set SETORES_DEFENSIVOS within SETORES;
set SETORES_CICLICOS within SETORES;
set SETORES_COMMODITIES within SETORES;

# ================================================
# 2. VARIÁVEIS DE DECISÃO
# ================================================

var w {ATIVOS} >= 0;      # w[i]: peso do ativo i
var b {ATIVOS} binary;    # b[i]: 1 se o ativo i for escolhido
var y {SETORES} binary;   # y[s]: 1 se o setor s for escolhido

# ================================================
# 3. FUNÇÃO OBJETIVO
# ================================================

# Minimizar o risco (variância) do portfólio
minimize Risco_Portfolio:
    sum {i in ATIVOS, j in ATIVOS} w[i] * Sigma[i,j] * w[j];

# ================================================
# 4. RESTRIÇÕES
# ================================================

subject to
    # --- Restrições de Base ---
    Soma_Pesos: sum {i in ATIVOS} w[i] = 1;
    Retorno_Alvo: sum {i in ATIVOS} mu[i] * w[i] >= R_target;
    Cardinalidade: sum {i in ATIVOS} b[i] = m;
    Aporte_Maximo {i in ATIVOS}: w[i] <= W_max * b[i];

    # --- Restrições de Conexão (Ligam a seleção de ativos à de setores) ---
    # Se pelo menos um ativo de um setor for escolhido, a variável do setor deve ser 1.
    Conecta_b_y_Inferior {s in SETORES}:
        y[s] <= sum {i in Ativos_Por_Setor[s]} b[i];

    # Se a variável do setor for 1, pelo menos um ativo deve ser escolhido.
    # Se a variável do setor for 0, nenhum ativo pode ser escolhido.
    Conecta_b_y_Superior {s in SETORES}:
        sum {i in Ativos_Por_Setor[s]} b[i] <= m * y[s]; # 'm' é um "Big-M" seguro

    # --- Implementação das 5 Regras Lógicas ---
    # Regra 1: Exclusividade entre Siderurgia e Construção Civil
    Exclusividade_Ciclicos:
        y['Siderurgia'] + y['Construcao_Civil'] <= 1;

    # Regra 2: Se investir em Tecnologia, deve investir em Energia Elétrica
    Condicional_Tec_Energia:
        y['Tecnologia'] <= y['Energia_Eletrica'];

    # Regra 3: Máximo de 2 setores do grupo financeiro
    Limite_Financeiro:
        sum {s in SETORES_FINANCEIROS} y[s] <= 2;

    # Regra 4: Diversificação Mínima de Perfil de Risco
    Min_Diversificacao_Defensivo:
        sum {s in SETORES_DEFENSIVOS} y[s] >= 1;

    Min_Diversificacao_Ciclico:
        sum {s in SETORES_CICLICOS} y[s] >= 1;

    # Regra 5: Controle de Exposição a Commodities
    Controle_Commodities:
        sum {s in SETORES_COMMODITIES} y[s] <= 1;