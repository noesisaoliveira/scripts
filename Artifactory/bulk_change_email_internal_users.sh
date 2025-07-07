#!/bin/bash

# Configuração
ARTIFACTORY_URL="https://ARTIFACTORY_URL/artifactory"

# Verificar argumento
if [[ "$1" != "-r" && "$1" != "-c" ]]; then
    echo "Please execute this script with one option. -r (Run script and apply changes in bulk), -c (Check execution, creates a log with changes but doesn’t change them directly)"
    exit 1
fi

# Pergunta o utilizador e a password da API
read -p "Introduza o utilizador da API: " API_USER
read -s -p "Introduza a password da API: " API_PASSWORD
echo

OLD_EMAIL="Old_email_to_be_changed"
NEW_EMAIL="New_email_to_be_changed"

LOG_FILE="update_email_log_$(date +%Y%m%d_%H%M%S).log"

# Obter os utilizadores do Artifactory
echo "A obter os utilizadores..."
users=$(curl -s -u "$API_USER:$API_PASSWORD" "$ARTIFACTORY_URL/api/security/users")

# Ciclo entre cada user
echo "$users" | jq -r '.[].name' | while read -r username; do
    # Obter os detalhes do user
    user_json=$(curl -s -u "$API_USER:$API_PASSWORD" "$ARTIFACTORY_URL/api/security/users/$username")

    # Extração do email atual
    current_email=$(echo "$user_json" | jq -r '.email // empty')

    # Se existir match com o mail configurado, processar
    if [[ "$current_email" == "$OLD_EMAIL" ]]; then
        echo "Encontrado utilizador para atualizar: $username"

        if [[ "$1" == "-r" ]]; then
            echo "A atualizar o email..."

            updated_json=$(echo "$user_json" | jq --arg new_email "$NEW_EMAIL" '.email = $new_email')

            # Enviar pedido PUT com JSON atualizado
            response=$(curl -s -o /dev/null -w "%{http_code}" -u "$API_USER:$API_PASSWORD" \
                -H "Content-Type: application/json" \
                -X PUT "$ARTIFACTORY_URL/api/security/users/$username" \
                -d "$updated_json")

            if [[ "$response" == "200" ]]; then
                echo "Sucesso na atualização do email : $username"
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Atualizado: $username" >> "$LOG_FILE"
            else
                echo "Falha na atualização do email : $username (HTTP $response)"
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Falha: $username (HTTP $response)" >> "$LOG_FILE"
            fi
        else
            echo "Modo de verificação: o email do user $username vai ser alterado se executar o script com a flag -r."
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Verificação: $username (email atual: $current_email)" >> "$LOG_FILE"
        fi
    fi
done
