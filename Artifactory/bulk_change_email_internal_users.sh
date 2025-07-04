#!/bin/bash

# Configuração
ARTIFACTORY_URL="https://ARTIFACTORY_URL/artifactory"
API_USER="admin"
API_PASSWORD="password"

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

    # Se existir match com o mail configurado, alterar o email para o novo mail
    if [[ "$current_email" == "$OLD_EMAIL" ]]; then
        echo "A atualizar o email..."

        updated_json=$(echo "$user_json" | jq --arg new_email "$NEW_EMAIL" '.email = $new_email')

        # Enviar pedido PUT com JSON atualizado
        response=$(curl -s -o /dev/null -w "%{http_code}" -u "$API_USER:$API_PASSWORD" \
            -H "Content-Type: application/json" \
            -X PUT "$ARTIFACTORY_URL/api/security/users/$username" \
            -d "$updated_json")

        if [[ "$response" == "200" ]]; then
            echo "Sucesso na atualização do email em: $username"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Atualizado: $username" >> "$LOG_FILE"
        else
            echo "Falha na atualização do email em: $username (HTTP $response)"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Falha: $username (HTTP $response)" >> "$LOG_FILE"
        fi
    fi
done
