#!/bin/bash
# Nome do Script
# bulk_change_email_internal_artifactory_users.sh

# O que faz?
# Este script tem como objetivo atualizar em massa o e-mail de utilizadores internos do Jfrog Artifactory.
# É necessário configurar o e-mail antigo e o novo, o script acede por API do Artifactory para verificar os utilizadores com o email antigo a alterar e atualiza-los com o novo e-mail.
# Este script também cria um arquivo de log com todas as atualizações e falhas.


# Notas para a execução deste script
# Validar se o jq está instalado, caso não esteja é necesário instalar

# Editar o script e na área de configuração é necessário introduzir os seguintes dados:
        
#        Configuração:
#        ARTIFACTORY_URL="https://ARTIFACTORY_URL/artifactory"
#        OLD_EMAIL="Old_email_to_be_changed"
#        NEW_EMAIL="New_email_to_be_changed"

# Para executar o script é necessário indicar uma opção:

#        -c para validar os users que vão ser alterados de acordo com o old email introduzido no script, é criado um logfile com a lista de users que seriam alterados;
#        -r para executar o script e alterar em massa todos os users encontrados com o old email;
#        -1 para executar o script e alterar apenas o primeiro match com o old_email, depois para a atualização.

# Quando o script é executado, é perguntado o utilizador Artifactory com permissões para alteração dos emails e a respectiva password.

# Garantir permissões de execução neste script
# chmod +x bulk_change_email_internal_users.sh

# Logging
# Durante a execução é criado um ficheiro log no mesmo diretório com o nome: update_email_log_<data_hora>.log
# Durante a execução são criados os ficheiros json com o payload de cada user com o nome "user_dump_%%USERNAME%%.json" a alterar para debug se necessário

# São registados no log as atualizações bem-sucedidas e as falhas, apenas para os utilizadores cujo email é necessário alterar.

# Configuração
ARTIFACTORY_URL="https://artifactory_url.jfrog.io/artifactory"
OLD_EMAIL="old_email"
NEW_EMAIL="new_email"

# Verificar argumento
if [[ "$1" != "-r" && "$1" != "-c" && "$1" != "-1" ]]; then
    echo "Please execute this script with one option. -r (Run script and apply changes in bulk), -c (Check execution, creates a log with changes but doesn’t change them directly), -1 (Change only the first matched user and stop)"
    exit 1
fi

# Pergunta o utilizador e a password da API
read -p "Introduza o utilizador da API: " API_USER
read -s -p "Introduza a password da API: " API_PASSWORD
echo

LOG_FILE="update_email_log_$(date +%Y%m%d_%H%M%S).log"

# Obter os utilizadores do Artifactory
echo "A obter os utilizadores..."
users=$(curl -s -u "$API_USER:$API_PASSWORD" "$ARTIFACTORY_URL/api/security/users")

# Verifica se a chamada à API teve sucesso
if [[ -z "$users" || "$users" == "[]" ]]; then
    echo "Unable to reach Artifactory API URL, please check if Artifactory is available"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Unable to reach Artifactory API URL, please check if Artifactory is available" >> "$LOG_FILE"
    exit 1
fi

# Ciclo entre cada utilizador
echo "$users" | jq -r '.[].name' | while read -r username; do
    # Obter os detalhes do utilizador
    user_json=$(curl -s -u "$API_USER:$API_PASSWORD" "$ARTIFACTORY_URL/api/security/users/$username")

    # Extrai o email atual
    current_email=$(echo "$user_json" | jq -r '.email // empty')

    # Se for o email antigo, altera
    if [[ "$current_email" == "$OLD_EMAIL" ]]; then
        echo "🔍 Encontrado utilizador para atualizar: $username"
        echo "$user_json" > "user_dump_$username.json"

        if [[ "$1" == "-r" || "$1" == "-1" ]]; then
            echo "🔧 A atualizar o email..."

            # Atualiza apenas os campos necessários
            updated_json=$(echo "$user_json" | jq --arg email "$NEW_EMAIL" --arg password "dummy" '
                .email = $email
                | .password = $password
                | .profileUpdatable = false
            ')

            echo "Payload JSON enviado:"
            echo "$updated_json"

            # Enviar o PUT
            response=$(curl -s -w "\n%{http_code}" -u "$API_USER:$API_PASSWORD" \
                -H "Content-Type: application/json" \
                -X PUT "$ARTIFACTORY_URL/api/security/users/$username" \
                -d "$updated_json")

            body=$(echo "$response" | head -n -1)
            code=$(echo "$response" | tail -n1)

            if [[ "$code" == "200" || "$code" == "201" ]]; then
                echo "Sucesso na atualização do email : $username"
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Atualizado: $username" >> "$LOG_FILE"
            else
                echo "Falha na atualização do email : $username (HTTP $code)"
                echo "Resposta do servidor:"
                echo "$body"
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Falha: $username (HTTP $code)" >> "$LOG_FILE"
            fi

        elif [[ "$1" == "-c" ]]; then
            echo "Modo de verificação: o email do utilizador $username vai ser alterado se executar o script com a flag -r."
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Verificação: $username (email atual: $current_email)" >> "$LOG_FILE"
        fi

        if [[ "$1" == "-1" ]]; then
            echo "Alteração única realizada. A terminar."
            exit 0
        fi
    fi
done
