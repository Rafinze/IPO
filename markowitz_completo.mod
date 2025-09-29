
set ATIVOS; # o universo de todas as P=53 ações
set SETORES; # um conjunto com todos os setores

# mapeia quais ativos pertencem a cada setor. Ex: Ativos_Por_Setor['Bancario']
set Ativos_Por_Setor {SETORES} within ATIVOS;

param m;
param W_max;
param R_target;

param mu {ATIVOS};
param Sigma {ATIVOS, ATIVOS};

set SETORES_FINANCEIROS within SETORES;
set SETORES_DEFENSIVOS within SETORES;
set SETORES_CICLICOS within SETORES;
set SETORES_COMMODITIES within SETORES;

var w {ATIVOS} >= 0;      # w[i]: peso do ativo i
var b {ATIVOS} binary;    # b[i]: 1 se o ativo i for escolhido
var y {SETORES} binary;   # y[s]: 1 se o setor s for escolhido

minimize Risco_Portfolio:
    sum {i in ATIVOS, j in ATIVOS} w[i] * Sigma[i,j] * w[j];


subject to
    Soma_Pesos: sum {i in ATIVOS} w[i] = 1;
    Retorno_Alvo: sum {i in ATIVOS} mu[i] * w[i] >= R_target;
    Cardinalidade: sum {i in ATIVOS} b[i] = m;
    Aporte_Maximo {i in ATIVOS}: w[i] <= W_max * b[i];

    # se pelo menos um ativo de um setor for escolhido, a variável do setor é 1.
    Conecta_b_y_Inferior {s in SETORES}:
        y[s] <= sum {i in Ativos_Por_Setor[s]} b[i];

    # se a variável do setor for 1, pelo menos um ativo deve ser escolhido.
    # se a variável do setor for 0, nenhum ativo pode ser escolhido.
    Conecta_b_y_Superior {s in SETORES}:
        sum {i in Ativos_Por_Setor[s]} b[i] <= m * y[s]; # 'm' é um "Big-M" seguro

    # Regra 1
    Exclusividade_Ciclicos:
        y['Siderurgia'] + y['Construcao_Civil'] <= 1;

    # Regra 2
    Condicional_Tec_Energia:
        y['Tecnologia'] <= y['Energia_Eletrica'];

    # Regra 3
    Limite_Financeiro:
        sum {s in SETORES_FINANCEIROS} y[s] <= 2;

    # Regra 4
    Min_Diversificacao_Defensivo:
        sum {s in SETORES_DEFENSIVOS} y[s] >= 1;

    Min_Diversificacao_Ciclico:
        sum {s in SETORES_CICLICOS} y[s] >= 1;

    # Regra 5
    Controle_Commodities:

        sum {s in SETORES_COMMODITIES} y[s] <= 1;
