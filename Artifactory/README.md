# Script Name
bulk_change_email_users.sh

# What it does?
This script is intentioned to bulk update the email on internal users for Jfrog Artifactory
You configure the old email and the new email, and the script goes into Artifactory API to retrive the users and update them with the new email.
It also create a log file with all the updates and failures. 


# Notas para a execução deste script
Validar se o jq está instalado, caso não esteja é necesário instalar

# Garantir permissões de execução neste script
chmod +x bulk_change_email_internal_users.sh

# Logging
Durante a execução é criado um ficheiro log no mesmo diretório com o nome: update_email_log_<data_hora>.log

São registados no log as atualizações bem-sucedidas e as falhas, apenas para os utilizadores cujo email é necessário alterar.
