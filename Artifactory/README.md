# Nome do Script
bulk_change_email_internal_artifactory_users.sh

# O que faz?
Este script tem como objetivo atualizar em massa o e-mail de utilizadores internos do Jfrog Artifactory.
É necessário configurar o e-mail antigo e o novo, o script acede por API do Artifactory para verificar os utilizadores com o email antigo a alterar e atualiza-los com o novo e-mail.
Este script também cria um arquivo de log com todas as atualizações e falhas.


# Notas para a execução deste script
Validar se o jq está instalado, caso não esteja é necesário instalar

Editar o script e na área de configuração é necessário introduzir os seguintes dados:
        
        Configuração:
        ARTIFACTORY_URL="https://ARTIFACTORY_URL/artifactory"
        OLD_EMAIL="Old_email_to_be_changed"
        NEW_EMAIL="New_email_to_be_changed"

Para executar o script é necessário indicar uma opção:

        -c para validar os users que vão ser alterados de acordo com o old email introduzido no script, é criado um logfile com a lista de users que seriam alterados;
        -r para executar o script e alterar em massa todos os users encontrados com o old email;
        -1 para executar o script e alterar apenas o primeiro match com o old_email, depois para a atualização.

Quando o script é executado, é perguntado ao utilizador o utilizador Artifactory com permissões para alteração dos emails e a respectiva password.

# Garantir permissões de execução neste script
chmod +x bulk_change_email_internal_users.sh

# Logging
Durante a execução é criado um ficheiro log no mesmo diretório com o nome: update_email_log_<data_hora>.log
Durante a execução são criados os ficheiros json com o payload de cada user com o nome "user_dump_%%USERNAME%%.json" a alterar para debug se necessário

São registados no log as atualizações bem-sucedidas e as falhas, apenas para os utilizadores cujo email é necessário alterar.
