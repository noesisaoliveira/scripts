#!/bin/bash

# Configuração
ARTIFACTORY_URL="https://artifactory.jfrog.io/artifactory"

# Verificar argumento
if [[ "$1" != "-r" && "$1" != "-c" && "$1" != "-1" ]]; then
    echo "Please execute this script with one option. -r (Run script and apply changes in bulk), -c (Check execution, creates a log with changes but doesn’t change them directly), -1 (Change only the first matched user and stop)"
    exit 1
fi

# Pergunta o utilizador e a password da API
read -p "Introduza o utilizador da API: " API_USER
read -s -p "Introduza a password da API: " API_PASSWORD
echo

OLD_EMAIL="old_email"
NEW_EMAIL="new_email"

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

# Ciclo entre cada user
echo "$users" | jq -r '.[].name' | while read -r username; do
    # Obter os detalhes do user
    user_json=$(curl -s -u "$API_USER:$API_PASSWORD" "$ARTIFACTORY_URL/api/security/users/$username")

    # Extração do email atual
    current_email=$(echo "$user_json" | jq -r '.email // empty')

    # Se existir match com o mail configurado, processar
    if [[ "$current_email" == "$OLD_EMAIL" ]]; then
        echo "Encontrado utilizador para atualizar: $username"

        # Dump JSON do user para debug
        echo "$user_json" > "user_dump_$username.json"

        if [[ "$1" == "-r" || "$1" == "-1" ]]; then
            echo "A atualizar o email..."

            # Criar payload sem mexer em grupos se existirem
            updated_json=$(echo "$user_json" | jq --arg email "$NEW_EMAIL" --arg password "dummy" '
            {
              name: .name,
              email: $email,
              password: $password,
              admin: (.admin // false),
              disableUIAccess: (.disableUIAccess // false),
              internalPasswordDisabled: (.internalPasswordDisabled // false),
              profileUpdatable: false
            }
            + (if has("groups") then {groups: .groups} else {} end)')

            echo "Payload JSON enviado:"
            echo "$updated_json" | jq

            # Fazer PUT request e capturar a resposta completa
            response=$(curl -s -w "\n%{http_code}" -u "$API_USER:$API_PASSWORD" \
                -H "Content-Type: application/json" \
                -X PUT "$ARTIFACTORY_URL/api/security/users/$username" \
                -d "$updated_json")

            http_body=$(echo "$response" | head -n 1)
            http_code=$(echo "$response" | tail -n1)

            if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
                echo "✅ Sucesso na atualização do email : $username"
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Atualizado: $username" >> "$LOG_FILE"
            else
                echo "❌ Falha na atualização do email : $username (HTTP $http_code)"
                echo "Resposta do servidor:"
                echo "$http_body"
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Falha: $username (HTTP $http_code) - $http_body" >> "$LOG_FILE"
            fi
        elif [[ "$1" == "-c" ]]; then
            echo "Modo de verificação: o email do user $username vai ser alterado se executar o script com a flag -r."
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Verificação: $username (email atual: $current_email)" >> "$LOG_FILE"
        fi

        # Se a opção for -1, parar após o primeiro
        if [[ "$1" == "-1" ]]; then
            echo "Alteração única realizada. A terminar."
            exit 0
        fi
    fi
done
